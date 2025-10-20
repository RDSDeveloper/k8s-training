import redis
import psycopg2
from psycopg2.extras import RealDictCursor
import json
import os
import time
from datetime import datetime

def get_redis_connection():
    """Get Redis connection"""
    return redis.Redis(
        host=os.getenv("REDIS_HOST", "redis-service"),
        port=int(os.getenv("REDIS_PORT", "6379")),
        decode_responses=True
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

def process_event(event_data):
    """Process analytics event and store in database"""
    try:
        event = json.loads(event_data)
        event_type = event.get("type")
        data = event.get("data", {})
        timestamp = event.get("timestamp")
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Insert analytics record
        cursor.execute("""
            INSERT INTO analytics (event_type, event_data, created_at)
            VALUES (%s, %s, %s)
        """, (event_type, json.dumps(data), timestamp))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        print(f"[{datetime.utcnow().isoformat()}] Processed event: {event_type}")
        
    except Exception as e:
        print(f"Error processing event: {e}")

def main():
    """Main worker loop"""
    print("Analytics Worker starting...")
    print(f"Redis: {os.getenv('REDIS_HOST', 'redis-service')}")
    print(f"Database: {os.getenv('DB_HOST', 'postgres-service')}")
    
    r = get_redis_connection()
    
    print("Worker ready. Waiting for events...")
    
    while True:
        try:
            # Blocking pop from Redis list (BRPOP with timeout)
            result = r.brpop("analytics:events", timeout=5)
            
            if result:
                queue_name, event_data = result
                process_event(event_data)
        
        except Exception as e:
            print(f"Worker error: {e}")
            time.sleep(5)

if __name__ == "__main__":
    main()

