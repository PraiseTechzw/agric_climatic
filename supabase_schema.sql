-- =====================================================
-- Agricultural Climate App - Supabase Database Schema
-- =====================================================
-- This script creates all necessary tables for the agricultural climate app
-- including weather data, air quality, pollen data, astronomy, and alerts

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- =====================================================
-- WEATHER DATA TABLES
-- =====================================================

-- Main weather data table with enhanced fields
CREATE TABLE IF NOT EXISTS weather_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date_time TIMESTAMPTZ NOT NULL,
    location_name VARCHAR(100) NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    temperature DECIMAL(5, 2) NOT NULL,
    humidity DECIMAL(5, 2) NOT NULL,
    wind_speed DECIMAL(5, 2) NOT NULL,
    wind_degree INTEGER,
    wind_direction VARCHAR(10),
    wind_gust DECIMAL(5, 2),
    condition VARCHAR(50) NOT NULL,
    description TEXT,
    icon VARCHAR(10),
    pressure DECIMAL(7, 2) NOT NULL,
    visibility DECIMAL(5, 2),
    precipitation DECIMAL(5, 2) DEFAULT 0.0,
    uv_index DECIMAL(4, 2),
    feels_like DECIMAL(5, 2),
    dew_point DECIMAL(5, 2),
    cloud_cover DECIMAL(5, 2),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Air quality data table
CREATE TABLE IF NOT EXISTS air_quality_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    weather_data_id UUID REFERENCES weather_data(id) ON DELETE CASCADE,
    co DECIMAL(8, 3), -- Carbon Monoxide (μg/m3)
    o3 DECIMAL(8, 3), -- Ozone (μg/m3)
    no2 DECIMAL(8, 3), -- Nitrogen dioxide (μg/m3)
    so2 DECIMAL(8, 3), -- Sulphur dioxide (μg/m3)
    pm2_5 DECIMAL(8, 3), -- PM2.5 (μg/m3)
    pm10 DECIMAL(8, 3), -- PM10 (μg/m3)
    us_epa_index INTEGER CHECK (us_epa_index >= 1 AND us_epa_index <= 6),
    gb_defra_index INTEGER CHECK (gb_defra_index >= 1 AND gb_defra_index <= 10),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Pollen data table for agricultural planning
CREATE TABLE IF NOT EXISTS pollen_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    weather_data_id UUID REFERENCES weather_data(id) ON DELETE CASCADE,
    hazel DECIMAL(8, 3), -- Pollen grains per cubic meter
    alder DECIMAL(8, 3),
    birch DECIMAL(8, 3),
    oak DECIMAL(8, 3),
    grass DECIMAL(8, 3),
    mugwort DECIMAL(8, 3),
    ragweed DECIMAL(8, 3),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Astronomy data for agricultural timing
CREATE TABLE IF NOT EXISTS astronomy_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date DATE NOT NULL,
    location_name VARCHAR(100) NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    sunrise TIME NOT NULL,
    sunset TIME NOT NULL,
    moonrise TIME,
    moonset TIME,
    moon_phase VARCHAR(50),
    moon_illumination DECIMAL(5, 2),
    is_moon_up BOOLEAN DEFAULT FALSE,
    is_sun_up BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Weather alerts table (enhanced)
CREATE TABLE IF NOT EXISTS weather_alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    duration VARCHAR(100),
    location VARCHAR(255) NOT NULL,
    date TIMESTAMPTZ NOT NULL,
    icon VARCHAR(50),
    type VARCHAR(50) DEFAULT 'weather',
    effective_date TIMESTAMPTZ,
    expires_date TIMESTAMPTZ,
    areas TEXT,
    category VARCHAR(50),
    urgency VARCHAR(50),
    certainty VARCHAR(50),
    event VARCHAR(100),
    instruction TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- AGRICULTURAL DATA TABLES
-- =====================================================

-- Soil data table
CREATE TABLE IF NOT EXISTS soil_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    location_name VARCHAR(100) NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    soil_temperature DECIMAL(5, 2),
    soil_moisture DECIMAL(5, 2),
    ph_level DECIMAL(3, 1),
    organic_matter DECIMAL(5, 2),
    nitrogen_level DECIMAL(5, 2),
    phosphorus_level DECIMAL(5, 2),
    potassium_level DECIMAL(5, 2),
    soil_type VARCHAR(50),
    depth_cm INTEGER,
    date_measured TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Agricultural recommendations table
CREATE TABLE IF NOT EXISTS agricultural_recommendations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    location_name VARCHAR(100) NOT NULL,
    crop_type VARCHAR(100),
    recommendation_type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    weather_condition VARCHAR(100),
    temperature_range VARCHAR(50),
    humidity_range VARCHAR(50),
    precipitation_range VARCHAR(50),
    wind_condition VARCHAR(50),
    soil_condition VARCHAR(100),
    effective_date DATE,
    expiry_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Agro-climatic predictions table
CREATE TABLE IF NOT EXISTS agro_climatic_predictions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    location_name VARCHAR(100) NOT NULL,
    prediction_date DATE NOT NULL,
    prediction_type VARCHAR(50) NOT NULL,
    crop_type VARCHAR(100),
    predicted_condition VARCHAR(100),
    confidence_level DECIMAL(5, 2) CHECK (confidence_level >= 0 AND confidence_level <= 100),
    temperature_prediction DECIMAL(5, 2),
    humidity_prediction DECIMAL(5, 2),
    precipitation_prediction DECIMAL(5, 2),
    wind_prediction DECIMAL(5, 2),
    soil_moisture_prediction DECIMAL(5, 2),
    risk_level VARCHAR(20) CHECK (risk_level IN ('low', 'medium', 'high', 'critical')),
    recommendation TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- USER AND NOTIFICATION TABLES
-- =====================================================

-- User preferences table
CREATE TABLE IF NOT EXISTS user_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID,
    location_name VARCHAR(100),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    notification_enabled BOOLEAN DEFAULT TRUE,
    alert_severity VARCHAR(20) DEFAULT 'medium' CHECK (alert_severity IN ('low', 'medium', 'high', 'critical')),
    crop_types TEXT[], -- Array of crop types user is interested in
    preferred_language VARCHAR(10) DEFAULT 'en',
    timezone VARCHAR(50) DEFAULT 'Africa/Harare',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Notifications table
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) NOT NULL,
    priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    is_read BOOLEAN DEFAULT FALSE,
    is_sent BOOLEAN DEFAULT FALSE,
    scheduled_at TIMESTAMPTZ,
    sent_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Weather data indexes
CREATE INDEX IF NOT EXISTS idx_weather_data_datetime ON weather_data(date_time);
CREATE INDEX IF NOT EXISTS idx_weather_data_location ON weather_data(location_name);
CREATE INDEX IF NOT EXISTS idx_weather_data_location_datetime ON weather_data(location_name, date_time);
CREATE INDEX IF NOT EXISTS idx_weather_data_condition ON weather_data(condition);

-- Air quality indexes
CREATE INDEX IF NOT EXISTS idx_air_quality_weather_id ON air_quality_data(weather_data_id);
CREATE INDEX IF NOT EXISTS idx_air_quality_pm25 ON air_quality_data(pm2_5);
CREATE INDEX IF NOT EXISTS idx_air_quality_pm10 ON air_quality_data(pm10);

-- Pollen data indexes
CREATE INDEX IF NOT EXISTS idx_pollen_weather_id ON pollen_data(weather_data_id);
CREATE INDEX IF NOT EXISTS idx_pollen_grass ON pollen_data(grass);
CREATE INDEX IF NOT EXISTS idx_pollen_ragweed ON pollen_data(ragweed);

-- Astronomy data indexes
CREATE INDEX IF NOT EXISTS idx_astronomy_date ON astronomy_data(date);
CREATE INDEX IF NOT EXISTS idx_astronomy_location ON astronomy_data(location_name);
CREATE INDEX IF NOT EXISTS idx_astronomy_location_date ON astronomy_data(location_name, date);

-- Weather alerts indexes
CREATE INDEX IF NOT EXISTS idx_weather_alerts_date ON weather_alerts(date);
CREATE INDEX IF NOT EXISTS idx_weather_alerts_severity ON weather_alerts(severity);
CREATE INDEX IF NOT EXISTS idx_weather_alerts_location ON weather_alerts(location);
CREATE INDEX IF NOT EXISTS idx_weather_alerts_expires ON weather_alerts(expires_date);

-- Soil data indexes
CREATE INDEX IF NOT EXISTS idx_soil_data_location ON soil_data(location_name);
CREATE INDEX IF NOT EXISTS idx_soil_data_date ON soil_data(date_measured);
CREATE INDEX IF NOT EXISTS idx_soil_data_location_date ON soil_data(location_name, date_measured);

-- Agricultural recommendations indexes
CREATE INDEX IF NOT EXISTS idx_ag_rec_location ON agricultural_recommendations(location_name);
CREATE INDEX IF NOT EXISTS idx_ag_rec_type ON agricultural_recommendations(recommendation_type);
CREATE INDEX IF NOT EXISTS idx_ag_rec_priority ON agricultural_recommendations(priority);
CREATE INDEX IF NOT EXISTS idx_ag_rec_active ON agricultural_recommendations(is_active);

-- Agro-climatic predictions indexes
CREATE INDEX IF NOT EXISTS idx_agro_pred_location ON agro_climatic_predictions(location_name);
CREATE INDEX IF NOT EXISTS idx_agro_pred_date ON agro_climatic_predictions(prediction_date);
CREATE INDEX IF NOT EXISTS idx_agro_pred_type ON agro_climatic_predictions(prediction_type);
CREATE INDEX IF NOT EXISTS idx_agro_pred_risk ON agro_climatic_predictions(risk_level);

-- User preferences indexes
CREATE INDEX IF NOT EXISTS idx_user_prefs_user_id ON user_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_user_prefs_location ON user_preferences(location_name);

-- Notifications indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_scheduled ON notifications(scheduled_at);

-- =====================================================
-- FUNCTIONS AND TRIGGERS
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
CREATE TRIGGER update_weather_data_updated_at 
    BEFORE UPDATE ON weather_data 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_preferences_updated_at 
    BEFORE UPDATE ON user_preferences 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to calculate air quality index
CREATE OR REPLACE FUNCTION calculate_air_quality_index(
    pm25 DECIMAL,
    pm10 DECIMAL,
    o3 DECIMAL,
    no2 DECIMAL,
    so2 DECIMAL,
    co DECIMAL
)
RETURNS INTEGER AS $$
DECLARE
    aqi INTEGER := 1;
BEGIN
    -- Simple AQI calculation based on PM2.5 (most common indicator)
    IF pm25 IS NOT NULL THEN
        IF pm25 <= 12 THEN
            aqi := 1; -- Good
        ELSIF pm25 <= 35.4 THEN
            aqi := 2; -- Moderate
        ELSIF pm25 <= 55.4 THEN
            aqi := 3; -- Unhealthy for sensitive groups
        ELSIF pm25 <= 150.4 THEN
            aqi := 4; -- Unhealthy
        ELSIF pm25 <= 250.4 THEN
            aqi := 5; -- Very Unhealthy
        ELSE
            aqi := 6; -- Hazardous
        END IF;
    END IF;
    
    RETURN aqi;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to get pollen risk level
CREATE OR REPLACE FUNCTION get_pollen_risk_level(pollen_count DECIMAL)
RETURNS VARCHAR(20) AS $$
BEGIN
    IF pollen_count IS NULL THEN
        RETURN 'Unknown';
    ELSIF pollen_count >= 1 AND pollen_count < 20 THEN
        RETURN 'Low';
    ELSIF pollen_count >= 20 AND pollen_count < 100 THEN
        RETURN 'Moderate';
    ELSIF pollen_count >= 100 AND pollen_count < 300 THEN
        RETURN 'High';
    ELSIF pollen_count >= 300 THEN
        RETURN 'Very High';
    ELSE
        RETURN 'Unknown';
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- =====================================================
-- SAMPLE DATA FOR ZIMBABWE LOCATIONS
-- =====================================================

-- Insert sample Zimbabwe cities with coordinates
INSERT INTO user_preferences (location_name, latitude, longitude, crop_types) VALUES
('Harare', -17.8252, 31.0335, ARRAY['maize', 'tobacco', 'cotton']),
('Bulawayo', -20.1569, 28.5891, ARRAY['maize', 'wheat', 'sorghum']),
('Chitungwiza', -18.0128, 31.0756, ARRAY['maize', 'vegetables']),
('Mutare', -18.9707, 32.6729, ARRAY['tobacco', 'coffee', 'tea']),
('Gweru', -19.4500, 29.8167, ARRAY['maize', 'wheat', 'sorghum']),
('Kwekwe', -18.9289, 29.8149, ARRAY['maize', 'tobacco', 'cotton']),
('Kadoma', -18.3333, 29.9167, ARRAY['maize', 'tobacco']),
('Masvingo', -20.0737, 30.8278, ARRAY['maize', 'sorghum', 'millet']),
('Chinhoyi', -17.3667, 30.2000, ARRAY['maize', 'tobacco']),
('Marondera', -18.1853, 31.5519, ARRAY['maize', 'tobacco', 'vegetables'])
ON CONFLICT DO NOTHING;

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE weather_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE air_quality_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE pollen_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE astronomy_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE weather_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE soil_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE agricultural_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE agro_climatic_predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Public read access for weather data (for agricultural app)
CREATE POLICY "Public read access for weather data" ON weather_data
    FOR SELECT USING (true);

CREATE POLICY "Public read access for air quality" ON air_quality_data
    FOR SELECT USING (true);

CREATE POLICY "Public read access for pollen data" ON pollen_data
    FOR SELECT USING (true);

CREATE POLICY "Public read access for astronomy data" ON astronomy_data
    FOR SELECT USING (true);

CREATE POLICY "Public read access for weather alerts" ON weather_alerts
    FOR SELECT USING (true);

CREATE POLICY "Public read access for soil data" ON soil_data
    FOR SELECT USING (true);

CREATE POLICY "Public read access for agricultural recommendations" ON agricultural_recommendations
    FOR SELECT USING (true);

CREATE POLICY "Public read access for agro predictions" ON agro_climatic_predictions
    FOR SELECT USING (true);

-- User-specific policies for preferences and notifications
CREATE POLICY "Users can manage their own preferences" ON user_preferences
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own notifications" ON notifications
    FOR ALL USING (auth.uid() = user_id);

-- =====================================================
-- VIEWS FOR COMMON QUERIES
-- =====================================================

-- Current weather view with air quality and pollen data
CREATE OR REPLACE VIEW current_weather_view AS
SELECT 
    w.*,
    aq.co, aq.o3, aq.no2, aq.so2, aq.pm2_5, aq.pm10, aq.us_epa_index, aq.gb_defra_index,
    p.hazel, p.alder, p.birch, p.oak, p.grass, p.mugwort, p.ragweed
FROM weather_data w
LEFT JOIN air_quality_data aq ON w.id = aq.weather_data_id
LEFT JOIN pollen_data p ON w.id = p.weather_data_id
WHERE w.date_time >= NOW() - INTERVAL '1 hour'
ORDER BY w.date_time DESC;

-- Weather alerts view for active alerts
CREATE OR REPLACE VIEW active_weather_alerts AS
SELECT *
FROM weather_alerts
WHERE expires_date > NOW()
ORDER BY severity DESC, date DESC;

-- Agricultural recommendations by location
CREATE OR REPLACE VIEW location_recommendations AS
SELECT 
    ar.id,
    ar.location_name,
    ar.crop_type,
    ar.recommendation_type,
    ar.title,
    ar.description,
    ar.priority,
    ar.weather_condition as recommendation_weather_condition,
    ar.temperature_range,
    ar.humidity_range,
    ar.precipitation_range,
    ar.wind_condition,
    ar.soil_condition,
    ar.effective_date,
    ar.expiry_date,
    ar.is_active,
    ar.created_at,
    w.temperature,
    w.humidity,
    w.precipitation,
    w.condition as current_weather_condition
FROM agricultural_recommendations ar
LEFT JOIN LATERAL (
    SELECT temperature, humidity, precipitation, condition
    FROM weather_data
    WHERE location_name = ar.location_name
    ORDER BY date_time DESC
    LIMIT 1
) w ON true
WHERE ar.is_active = true
ORDER BY ar.priority DESC, ar.created_at DESC;

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================

-- This completes the database schema setup for the Agricultural Climate App
-- The schema includes:
-- - Enhanced weather data with air quality and pollen information
-- - Astronomy data for agricultural timing
-- - Soil data for agricultural planning
-- - Agricultural recommendations and predictions
-- - User preferences and notifications
-- - Comprehensive indexing for performance
-- - Row Level Security policies
-- - Useful views for common queries
-- - Sample data for Zimbabwe locations
