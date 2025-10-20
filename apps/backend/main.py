from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from typing import List
import psycopg2
from psycopg2.extras import RealDictCursor
import os
import redis
import json
from datetime import datetime

app = FastAPI(
    title="European Cities & Barbarian Invasions API",
    version="3.0.0",
    description="100% Automated CI/CD - GitHub Actions + ArgoCD"
)

# CORS for frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_db_connection():
    """Get PostgreSQL connection"""
    return psycopg2.connect(
        host=os.getenv("DB_HOST", "postgres-service"),
        port=os.getenv("DB_PORT", "5432"),
        database=os.getenv("DB_NAME", "invasions_db"),
        user=os.getenv("DB_USER", "postgres"),
        password=os.getenv("DB_PASSWORD", "postgres"),
        cursor_factory=RealDictCursor
    )

def get_redis_connection():
    """Get Redis connection"""
    return redis.Redis(
        host=os.getenv("REDIS_HOST", "redis-service"),
        port=int(os.getenv("REDIS_PORT", "6379")),
        decode_responses=True
    )

def publish_analytics_event(event_type: str, data: dict):
    """Publish event to Redis queue for analytics worker"""
    try:
        r = get_redis_connection()
        event = {
            "type": event_type,
            "data": data,
            "timestamp": datetime.utcnow().isoformat()
        }
        r.lpush("analytics:events", json.dumps(event))
    except Exception as e:
        print(f"Failed to publish analytics event: {e}")

@app.get("/")
def root():
    """Health check"""
    return {
        "service": "European Cities API",
        "version": "1.0",
        "status": "healthy"
    }

@app.get("/health")
def health():
    """Basic health check endpoint"""
    return {"status": "healthy", "service": "backend"}

@app.get("/health/live")
def liveness():
    """Liveness probe - is the app running?"""
    return {"status": "alive"}

@app.get("/health/ready")
def readiness():
    """Readiness probe - can the app handle traffic?"""
    try:
        # Check DB connection
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT 1")
        cursor.close()
        conn.close()
        
        # Check Redis connection
        r = get_redis_connection()
        r.ping()
        
        return {
            "status": "ready",
            "database": "connected",
            "redis": "connected"
        }
    except Exception as e:
        from fastapi.responses import JSONResponse
        return JSONResponse(
            status_code=503,
            content={
                "status": "not_ready",
                "error": str(e)
            }
        )

@app.get("/health/startup")
def startup():
    """Startup probe - has the app finished initializing?"""
    try:
        # Check DB connection
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM cities")
        cursor.close()
        conn.close()
        
        return {
            "status": "started",
            "database": "initialized"
        }
    except Exception as e:
        from fastapi.responses import JSONResponse
        return JSONResponse(
            status_code=503,
            content={
                "status": "starting",
                "error": str(e)
            }
        )

@app.get("/api/cities")
def get_cities():
    """Get all European cities (with Redis cache)"""
    try:
        # Try cache first
        r = get_redis_connection()
        cached = r.get("cities:all")
        
        if cached:
            return json.loads(cached)
        
        # Cache miss - query DB
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT 
                id,
                name,
                country,
                modern_name,
                description,
                (SELECT COUNT(*) FROM invasions WHERE city_id = cities.id) as invasion_count
            FROM cities
            ORDER BY name
        """)
        
        cities = cursor.fetchall()
        cursor.close()
        conn.close()
        
        result = {"cities": cities, "count": len(cities), "cached": False}
        
        # Store in cache (TTL 5 minutes)
        r.setex("cities:all", 300, json.dumps(result))
        
        # Publish analytics event
        publish_analytics_event("cities_listed", {"count": len(cities)})
        
        return result
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

@app.get("/api/cities/{city_id}")
def get_city(city_id: int):
    """Get city details"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT id, name, country, modern_name, description
            FROM cities
            WHERE id = %s
        """, (city_id,))
        
        city = cursor.fetchone()
        
        if not city:
            cursor.close()
            conn.close()
            raise HTTPException(status_code=404, detail="City not found")
        
        cursor.close()
        conn.close()
        
        return city
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

@app.get("/api/cities/{city_id}/invasions")
def get_city_invasions(city_id: int):
    """Get all invasions for a specific city (with Redis cache)"""
    try:
        # Try cache first
        r = get_redis_connection()
        cache_key = f"city:{city_id}:invasions"
        cached = r.get(cache_key)
        
        if cached:
            result = json.loads(cached)
            result["cached"] = True
            return result
        
        # Cache miss - query DB
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Check if city exists
        cursor.execute("SELECT id, name FROM cities WHERE id = %s", (city_id,))
        city = cursor.fetchone()
        
        if not city:
            cursor.close()
            conn.close()
            raise HTTPException(status_code=404, detail="City not found")
        
        # Get invasions
        cursor.execute("""
            SELECT 
                i.id,
                i.year,
                i.description,
                i.outcome,
                t.name as tribe_name,
                t.origin,
                t.leader
            FROM invasions i
            JOIN tribes t ON i.tribe_id = t.id
            WHERE i.city_id = %s
            ORDER BY i.year
        """, (city_id,))
        
        invasions = cursor.fetchall()
        
        cursor.close()
        conn.close()
        
        result = {
            "city": city,
            "invasions": invasions,
            "count": len(invasions),
            "cached": False
        }
        
        # Store in cache (TTL 5 minutes)
        r.setex(cache_key, 300, json.dumps(result))
        
        # Publish analytics event
        publish_analytics_event("city_invasions_viewed", {
            "city_id": city_id,
            "city_name": city["name"],
            "invasion_count": len(invasions)
        })
        
        return result
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

@app.get("/api/tribes")
def get_tribes():
    """Get all barbarian tribes"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT 
                id,
                name,
                origin,
                leader,
                description,
                (SELECT COUNT(*) FROM invasions WHERE tribe_id = tribes.id) as invasion_count
            FROM tribes
            ORDER BY name
        """)
        
        tribes = cursor.fetchall()
        cursor.close()
        conn.close()
        
        return {"tribes": tribes, "count": len(tribes)}
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

