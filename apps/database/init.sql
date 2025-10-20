-- European Cities & Barbarian Invasions Database
-- Historical data about barbarian invasions in Europe (300-1000 AD)

CREATE TABLE IF NOT EXISTS cities (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    modern_name VARCHAR(100),
    description TEXT
);

CREATE TABLE IF NOT EXISTS tribes (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    origin VARCHAR(100),
    leader VARCHAR(100),
    description TEXT
);

CREATE TABLE IF NOT EXISTS invasions (
    id SERIAL PRIMARY KEY,
    city_id INTEGER REFERENCES cities(id),
    tribe_id INTEGER REFERENCES tribes(id),
    year INTEGER NOT NULL,
    description TEXT,
    outcome VARCHAR(200)
);

-- Insert Cities
INSERT INTO cities (name, country, modern_name, description) VALUES
('Roma', 'Italia', 'Rome', 'Capital of the Roman Empire, sacked multiple times by barbarian tribes'),
('Lutetia', 'Gaul', 'Paris', 'Important Roman city in Gaul, attacked by Huns and later by Vikings'),
('Londinium', 'Britannia', 'London', 'Roman city in Britain, invaded by Angles, Saxons, and Vikings'),
('Constantinople', 'Eastern Rome', 'Istanbul', 'Capital of Byzantine Empire, attacked by numerous barbarian tribes'),
('Tolosa', 'Hispania', 'Toulouse', 'Visigothic capital in southern Gaul'),
('Toletum', 'Hispania', 'Toledo', 'Capital of Visigothic Kingdom in Hispania'),
('Ravenna', 'Italia', 'Ravenna', 'Capital of Western Roman Empire after 402 AD'),
('Mediolanum', 'Italia', 'Milan', 'Former capital of Western Roman Empire');

-- Insert Tribes
INSERT INTO tribes (name, origin, leader, description) VALUES
('Visigoths', 'Germanic', 'Alaric I', 'Germanic people who sacked Rome in 410 AD and founded kingdom in Hispania'),
('Vandals', 'Germanic', 'Genseric', 'Germanic tribe that sacked Rome in 455 AD and established kingdom in North Africa'),
('Ostrogoths', 'Germanic', 'Theodoric', 'Eastern Goths who conquered Italy and established kingdom'),
('Huns', 'Central Asia', 'Attila', 'Nomadic warriors from the steppes, terrorized Europe in 5th century'),
('Angles', 'Germanic', 'Various', 'Germanic tribe that invaded Britain and gave name to England'),
('Saxons', 'Germanic', 'Various', 'Germanic people who invaded Britain alongside Angles'),
('Vikings', 'Scandinavia', 'Various', 'Norse raiders who attacked throughout Europe from 8th-11th centuries'),
('Franks', 'Germanic', 'Clovis I', 'Germanic people who conquered Gaul and established Frankish Empire'),
('Lombards', 'Germanic', 'Alboin', 'Germanic tribe that invaded Italy in 568 AD'),
('Avars', 'Central Asia', 'Bayan I', 'Nomadic people who attacked Byzantine Empire');

-- Insert Invasions
-- Roma invasions
INSERT INTO invasions (city_id, tribe_id, year, description, outcome) VALUES
(1, 1, 410, 'Visigoths under Alaric I sacked Rome for three days', 'City looted but not destroyed'),
(1, 2, 455, 'Vandals under Genseric thoroughly looted Rome for two weeks', 'Massive plunder, term "vandalism" coined'),
(1, 3, 476, 'Odoacer deposed last Western Roman Emperor Romulus Augustulus', 'End of Western Roman Empire');

-- Lutetia/Paris invasions
INSERT INTO invasions (city_id, tribe_id, year, description, outcome) VALUES
(2, 4, 451, 'Attila the Hun approached Paris but was turned back', 'City saved, attributed to Saint Genevieve'),
(2, 8, 486, 'Franks under Clovis I conquered Paris', 'Became part of Frankish Kingdom'),
(2, 7, 845, 'Vikings raided Paris and extracted huge ransom', 'City paid 7,000 pounds of silver'),
(2, 7, 885, 'Vikings besieged Paris for nearly a year', 'City held out with fierce resistance');

-- Londinium/London invasions
INSERT INTO invasions (city_id, tribe_id, year, description, outcome) VALUES
(3, 5, 450, 'Angles began settling in Britain after Roman withdrawal', 'Gradual Anglo-Saxon conquest'),
(3, 6, 450, 'Saxons invaded alongside Angles', 'Romano-British pushed west'),
(3, 7, 842, 'Vikings sacked London', 'City heavily damaged'),
(3, 7, 871, 'Great Heathen Army attacked London', 'Danish control established');

-- Constantinople invasions
INSERT INTO invasions (city_id, tribe_id, year, description, outcome) VALUES
(4, 1, 378, 'Visigoths defeated Romans at Battle of Adrianople nearby', 'Emperor Valens killed'),
(4, 4, 441, 'Attila the Hun attacked Constantinople', 'City walls held, heavy tribute paid'),
(4, 10, 626, 'Avars besieged Constantinople', 'Siege failed, Byzantine victory');

-- Tolosa/Toulouse invasions
INSERT INTO invasions (city_id, tribe_id, year, description, outcome) VALUES
(5, 1, 418, 'Visigoths established capital in Tolosa', 'Became capital of Visigothic Kingdom'),
(5, 8, 507, 'Franks conquered Tolosa', 'End of Visigothic control in Gaul');

-- Toletum/Toledo invasions  
INSERT INTO invasions (city_id, tribe_id, year, description, outcome) VALUES
(6, 1, 534, 'Visigoths moved capital to Toletum', 'Became new capital of Visigothic Hispania'),
(6, 8, 712, 'Muslim conquest ended Visigothic kingdom', 'End of Visigothic rule');

-- Ravenna invasions
INSERT INTO invasions (city_id, tribe_id, year, description, outcome) VALUES
(7, 3, 493, 'Ostrogoths under Theodoric conquered Ravenna', 'Capital of Ostrogothic Kingdom'),
(7, 9, 568, 'Lombards invaded northern Italy', 'Byzantine control weakened');

-- Mediolanum/Milan invasions
INSERT INTO invasions (city_id, tribe_id, year, description, outcome) VALUES
(8, 4, 452, 'Attila the Hun sacked Mediolanum', 'City destroyed'),
(8, 1, 489, 'Visigoths passed through during campaigns', 'Temporary occupation'),
(8, 9, 569, 'Lombards captured Milan', 'Became part of Lombard Kingdom');

-- Analytics table for tracking user interactions
CREATE TABLE IF NOT EXISTS analytics (
    id SERIAL PRIMARY KEY,
    event_type VARCHAR(100) NOT NULL,
    event_data JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_analytics_event_type ON analytics(event_type);
CREATE INDEX IF NOT EXISTS idx_analytics_created_at ON analytics(created_at);

-- Success message
SELECT 'Database initialized successfully!' as message;
SELECT COUNT(*) as cities_count FROM cities;
SELECT COUNT(*) as tribes_count FROM tribes;
SELECT COUNT(*) as invasions_count FROM invasions;

