-- =====================================================
-- Agricultural Climate App - Supabase Functions
-- =====================================================
-- This script contains useful functions for the agricultural climate app

-- =====================================================
-- WEATHER DATA FUNCTIONS
-- =====================================================

-- Function to get current weather for a location
CREATE OR REPLACE FUNCTION get_current_weather(location_name_param VARCHAR(100))
RETURNS TABLE (
    id UUID,
    date_time TIMESTAMPTZ,
    location_name VARCHAR(100),
    temperature DECIMAL(5, 2),
    humidity DECIMAL(5, 2),
    wind_speed DECIMAL(5, 2),
    condition VARCHAR(50),
    description TEXT,
    pressure DECIMAL(7, 2),
    precipitation DECIMAL(5, 2),
    uv_index DECIMAL(4, 2),
    feels_like DECIMAL(5, 2),
    dew_point DECIMAL(5, 2),
    cloud_cover DECIMAL(5, 2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        w.id, w.date_time, w.location_name, w.temperature, w.humidity,
        w.wind_speed, w.condition, w.description, w.pressure, w.precipitation,
        w.uv_index, w.feels_like, w.dew_point, w.cloud_cover
    FROM weather_data w
    WHERE w.location_name = location_name_param
    AND w.date_time >= NOW() - INTERVAL '1 hour'
    ORDER BY w.date_time DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- Function to get weather forecast for a location
CREATE OR REPLACE FUNCTION get_weather_forecast(
    location_name_param VARCHAR(100),
    days_ahead INTEGER DEFAULT 7
)
RETURNS TABLE (
    id UUID,
    date_time TIMESTAMPTZ,
    location_name VARCHAR(100),
    temperature DECIMAL(5, 2),
    humidity DECIMAL(5, 2),
    wind_speed DECIMAL(5, 2),
    condition VARCHAR(50),
    description TEXT,
    precipitation DECIMAL(5, 2),
    uv_index DECIMAL(4, 2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        w.id, w.date_time, w.location_name, w.temperature, w.humidity,
        w.wind_speed, w.condition, w.description, w.precipitation, w.uv_index
    FROM weather_data w
    WHERE w.location_name = location_name_param
    AND w.date_time BETWEEN NOW() AND NOW() + (days_ahead || ' days')::INTERVAL
    ORDER BY w.date_time ASC;
END;
$$ LANGUAGE plpgsql;

-- Function to get historical weather data
CREATE OR REPLACE FUNCTION get_historical_weather(
    location_name_param VARCHAR(100),
    start_date DATE,
    end_date DATE
)
RETURNS TABLE (
    id UUID,
    date_time TIMESTAMPTZ,
    location_name VARCHAR(100),
    temperature DECIMAL(5, 2),
    humidity DECIMAL(5, 2),
    wind_speed DECIMAL(5, 2),
    condition VARCHAR(50),
    precipitation DECIMAL(5, 2),
    pressure DECIMAL(7, 2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        w.id, w.date_time, w.location_name, w.temperature, w.humidity,
        w.wind_speed, w.condition, w.precipitation, w.pressure
    FROM weather_data w
    WHERE w.location_name = location_name_param
    AND DATE(w.date_time) BETWEEN start_date AND end_date
    ORDER BY w.date_time ASC;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- AIR QUALITY FUNCTIONS
-- =====================================================

-- Function to get current air quality for a location
CREATE OR REPLACE FUNCTION get_current_air_quality(location_name_param VARCHAR(100))
RETURNS TABLE (
    weather_data_id UUID,
    co DECIMAL(8, 3),
    o3 DECIMAL(8, 3),
    no2 DECIMAL(8, 3),
    so2 DECIMAL(8, 3),
    pm2_5 DECIMAL(8, 3),
    pm10 DECIMAL(8, 3),
    us_epa_index INTEGER,
    gb_defra_index INTEGER,
    aqi_level VARCHAR(20)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        aq.weather_data_id, aq.co, aq.o3, aq.no2, aq.so2, aq.pm2_5, aq.pm10,
        aq.us_epa_index, aq.gb_defra_index,
        CASE 
            WHEN aq.us_epa_index = 1 THEN 'Good'
            WHEN aq.us_epa_index = 2 THEN 'Moderate'
            WHEN aq.us_epa_index = 3 THEN 'Unhealthy for Sensitive Groups'
            WHEN aq.us_epa_index = 4 THEN 'Unhealthy'
            WHEN aq.us_epa_index = 5 THEN 'Very Unhealthy'
            WHEN aq.us_epa_index = 6 THEN 'Hazardous'
            ELSE 'Unknown'
        END as aqi_level
    FROM air_quality_data aq
    JOIN weather_data w ON aq.weather_data_id = w.id
    WHERE w.location_name = location_name_param
    AND w.date_time >= NOW() - INTERVAL '1 hour'
    ORDER BY w.date_time DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- POLLEN DATA FUNCTIONS
-- =====================================================

-- Function to get current pollen data for a location
CREATE OR REPLACE FUNCTION get_current_pollen_data(location_name_param VARCHAR(100))
RETURNS TABLE (
    weather_data_id UUID,
    hazel DECIMAL(8, 3),
    alder DECIMAL(8, 3),
    birch DECIMAL(8, 3),
    oak DECIMAL(8, 3),
    grass DECIMAL(8, 3),
    mugwort DECIMAL(8, 3),
    ragweed DECIMAL(8, 3),
    grass_risk VARCHAR(20),
    ragweed_risk VARCHAR(20)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.weather_data_id, p.hazel, p.alder, p.birch, p.oak, p.grass, p.mugwort, p.ragweed,
        get_pollen_risk_level(p.grass) as grass_risk,
        get_pollen_risk_level(p.ragweed) as ragweed_risk
    FROM pollen_data p
    JOIN weather_data w ON p.weather_data_id = w.id
    WHERE w.location_name = location_name_param
    AND w.date_time >= NOW() - INTERVAL '1 hour'
    ORDER BY w.date_time DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- ASTRONOMY FUNCTIONS
-- =====================================================

-- Function to get astronomy data for a specific date and location
CREATE OR REPLACE FUNCTION get_astronomy_data(
    location_name_param VARCHAR(100),
    target_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    id UUID,
    date DATE,
    location_name VARCHAR(100),
    sunrise TIME,
    sunset TIME,
    moonrise TIME,
    moonset TIME,
    moon_phase VARCHAR(50),
    moon_illumination DECIMAL(5, 2),
    is_moon_up BOOLEAN,
    is_sun_up BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.id, a.date, a.location_name, a.sunrise, a.sunset, a.moonrise, a.moonset,
        a.moon_phase, a.moon_illumination, a.is_moon_up, a.is_sun_up
    FROM astronomy_data a
    WHERE a.location_name = location_name_param
    AND a.date = target_date
    ORDER BY a.date DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- WEATHER ALERTS FUNCTIONS
-- =====================================================

-- Function to get active weather alerts for a location
CREATE OR REPLACE FUNCTION get_active_weather_alerts(location_name_param VARCHAR(100))
RETURNS TABLE (
    id UUID,
    title VARCHAR(255),
    description TEXT,
    severity VARCHAR(20),
    duration VARCHAR(100),
    location VARCHAR(255),
    date TIMESTAMPTZ,
    icon VARCHAR(50),
    type VARCHAR(50),
    effective_date TIMESTAMPTZ,
    expires_date TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        wa.id, wa.title, wa.description, wa.severity, wa.duration, wa.location,
        wa.date, wa.icon, wa.type, wa.effective_date, wa.expires_date
    FROM weather_alerts wa
    WHERE (wa.location ILIKE '%' || location_name_param || '%' OR wa.location = 'All')
    AND wa.expires_date > NOW()
    ORDER BY wa.severity DESC, wa.date DESC;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- AGRICULTURAL FUNCTIONS
-- =====================================================

-- Function to get agricultural recommendations for a location
CREATE OR REPLACE FUNCTION get_agricultural_recommendations(
    location_name_param VARCHAR(100),
    crop_type_param VARCHAR(100) DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    location_name VARCHAR(100),
    crop_type VARCHAR(100),
    recommendation_type VARCHAR(50),
    title VARCHAR(255),
    description TEXT,
    priority VARCHAR(20),
    weather_condition VARCHAR(100),
    temperature_range VARCHAR(50),
    humidity_range VARCHAR(50),
    precipitation_range VARCHAR(50),
    effective_date DATE,
    expiry_date DATE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ar.id, ar.location_name, ar.crop_type, ar.recommendation_type, ar.title,
        ar.description, ar.priority, ar.weather_condition, ar.temperature_range,
        ar.humidity_range, ar.precipitation_range, ar.effective_date, ar.expiry_date
    FROM agricultural_recommendations ar
    WHERE ar.location_name = location_name_param
    AND ar.is_active = true
    AND (crop_type_param IS NULL OR ar.crop_type = crop_type_param)
    AND (ar.effective_date IS NULL OR ar.effective_date <= CURRENT_DATE)
    AND (ar.expiry_date IS NULL OR ar.expiry_date >= CURRENT_DATE)
    ORDER BY ar.priority DESC, ar.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get soil data for a location
CREATE OR REPLACE FUNCTION get_soil_data(
    location_name_param VARCHAR(100),
    days_back INTEGER DEFAULT 30
)
RETURNS TABLE (
    id UUID,
    location_name VARCHAR(100),
    soil_temperature DECIMAL(5, 2),
    soil_moisture DECIMAL(5, 2),
    ph_level DECIMAL(3, 1),
    organic_matter DECIMAL(5, 2),
    nitrogen_level DECIMAL(5, 2),
    phosphorus_level DECIMAL(5, 2),
    potassium_level DECIMAL(5, 2),
    soil_type VARCHAR(50),
    date_measured TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id, s.location_name, s.soil_temperature, s.soil_moisture, s.ph_level,
        s.organic_matter, s.nitrogen_level, s.phosphorus_level, s.potassium_level,
        s.soil_type, s.date_measured
    FROM soil_data s
    WHERE s.location_name = location_name_param
    AND s.date_measured >= NOW() - (days_back || ' days')::INTERVAL
    ORDER BY s.date_measured DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get agro-climatic predictions
CREATE OR REPLACE FUNCTION get_agro_climatic_predictions(
    location_name_param VARCHAR(100),
    prediction_type_param VARCHAR(50) DEFAULT NULL,
    days_ahead INTEGER DEFAULT 14
)
RETURNS TABLE (
    id UUID,
    location_name VARCHAR(100),
    prediction_date DATE,
    prediction_type VARCHAR(50),
    crop_type VARCHAR(100),
    predicted_condition VARCHAR(100),
    confidence_level DECIMAL(5, 2),
    temperature_prediction DECIMAL(5, 2),
    humidity_prediction DECIMAL(5, 2),
    precipitation_prediction DECIMAL(5, 2),
    risk_level VARCHAR(20),
    recommendation TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        acp.id, acp.location_name, acp.prediction_date, acp.prediction_type,
        acp.crop_type, acp.predicted_condition, acp.confidence_level,
        acp.temperature_prediction, acp.humidity_prediction, acp.precipitation_prediction,
        acp.risk_level, acp.recommendation
    FROM agro_climatic_predictions acp
    WHERE acp.location_name = location_name_param
    AND (prediction_type_param IS NULL OR acp.prediction_type = prediction_type_param)
    AND acp.prediction_date BETWEEN CURRENT_DATE AND CURRENT_DATE + (days_ahead || ' days')::INTERVAL
    ORDER BY acp.prediction_date ASC, acp.confidence_level DESC;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- ANALYTICS FUNCTIONS
-- =====================================================

-- Function to get weather statistics for a location
CREATE OR REPLACE FUNCTION get_weather_statistics(
    location_name_param VARCHAR(100),
    start_date DATE,
    end_date DATE
)
RETURNS TABLE (
    avg_temperature DECIMAL(5, 2),
    max_temperature DECIMAL(5, 2),
    min_temperature DECIMAL(5, 2),
    avg_humidity DECIMAL(5, 2),
    total_precipitation DECIMAL(5, 2),
    avg_wind_speed DECIMAL(5, 2),
    max_wind_speed DECIMAL(5, 2),
    avg_pressure DECIMAL(7, 2),
    sunny_days INTEGER,
    rainy_days INTEGER,
    cloudy_days INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ROUND(AVG(w.temperature), 2) as avg_temperature,
        ROUND(MAX(w.temperature), 2) as max_temperature,
        ROUND(MIN(w.temperature), 2) as min_temperature,
        ROUND(AVG(w.humidity), 2) as avg_humidity,
        ROUND(SUM(w.precipitation), 2) as total_precipitation,
        ROUND(AVG(w.wind_speed), 2) as avg_wind_speed,
        ROUND(MAX(w.wind_speed), 2) as max_wind_speed,
        ROUND(AVG(w.pressure), 2) as avg_pressure,
        COUNT(CASE WHEN w.condition = 'clear' THEN 1 END) as sunny_days,
        COUNT(CASE WHEN w.precipitation > 0 THEN 1 END) as rainy_days,
        COUNT(CASE WHEN w.condition IN ('cloudy', 'overcast') THEN 1 END) as cloudy_days
    FROM weather_data w
    WHERE w.location_name = location_name_param
    AND DATE(w.date_time) BETWEEN start_date AND end_date;
END;
$$ LANGUAGE plpgsql;

-- Function to get crop suitability based on weather conditions
CREATE OR REPLACE FUNCTION get_crop_suitability(
    location_name_param VARCHAR(100),
    crop_type_param VARCHAR(100)
)
RETURNS TABLE (
    crop_type VARCHAR(100),
    suitability_score INTEGER,
    temperature_score INTEGER,
    humidity_score INTEGER,
    precipitation_score INTEGER,
    overall_recommendation VARCHAR(100)
) AS $$
DECLARE
    current_temp DECIMAL(5, 2);
    current_humidity DECIMAL(5, 2);
    avg_precipitation DECIMAL(5, 2);
    temp_score INTEGER;
    humidity_score INTEGER;
    precip_score INTEGER;
    overall_score INTEGER;
BEGIN
    -- Get current weather conditions
    SELECT w.temperature, w.humidity, 
           (SELECT AVG(precipitation) FROM weather_data WHERE location_name = location_name_param AND date_time >= NOW() - INTERVAL '30 days')
    INTO current_temp, current_humidity, avg_precipitation
    FROM weather_data w
    WHERE w.location_name = location_name_param
    ORDER BY w.date_time DESC
    LIMIT 1;

    -- Calculate scores based on crop requirements (simplified logic)
    CASE crop_type_param
        WHEN 'maize' THEN
            temp_score := CASE 
                WHEN current_temp BETWEEN 20 AND 30 THEN 100
                WHEN current_temp BETWEEN 15 AND 35 THEN 80
                WHEN current_temp BETWEEN 10 AND 40 THEN 60
                ELSE 40
            END;
            humidity_score := CASE 
                WHEN current_humidity BETWEEN 50 AND 80 THEN 100
                WHEN current_humidity BETWEEN 40 AND 90 THEN 80
                ELSE 60
            END;
            precip_score := CASE 
                WHEN avg_precipitation BETWEEN 500 AND 1000 THEN 100
                WHEN avg_precipitation BETWEEN 300 AND 1200 THEN 80
                ELSE 60
            END;
        WHEN 'tobacco' THEN
            temp_score := CASE 
                WHEN current_temp BETWEEN 20 AND 28 THEN 100
                WHEN current_temp BETWEEN 15 AND 32 THEN 80
                ELSE 60
            END;
            humidity_score := CASE 
                WHEN current_humidity BETWEEN 60 AND 80 THEN 100
                WHEN current_humidity BETWEEN 50 AND 90 THEN 80
                ELSE 60
            END;
            precip_score := CASE 
                WHEN avg_precipitation BETWEEN 400 AND 800 THEN 100
                                WHEN avg_precipitation BETWEEN 300 AND 1000 THEN 80
                ELSE 60
            END;
        ELSE
            temp_score := 50;
            humidity_score := 50;
            precip_score := 50;
    END CASE;

    overall_score := (temp_score + humidity_score + precip_score) / 3;

    RETURN QUERY
    SELECT 
        crop_type_param,
        overall_score,
        temp_score,
        humidity_score,
        precip_score,
        CASE 
            WHEN overall_score >= 80 THEN 'Highly Suitable'
            WHEN overall_score >= 60 THEN 'Moderately Suitable'
            WHEN overall_score >= 40 THEN 'Marginally Suitable'
            ELSE 'Not Suitable'
        END;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- NOTIFICATION FUNCTIONS
-- =====================================================

-- Function to create weather alert notification
CREATE OR REPLACE FUNCTION create_weather_alert_notification()
RETURNS TRIGGER AS $$
BEGIN
    -- Create notification for all users in the affected area
    INSERT INTO notifications (user_id, title, message, type, priority, scheduled_at)
    SELECT 
        up.user_id,
        'Weather Alert: ' || NEW.title,
        NEW.description,
        'weather_alert',
        CASE NEW.severity
            WHEN 'critical' THEN 'urgent'
            WHEN 'high' THEN 'high'
            WHEN 'medium' THEN 'medium'
            ELSE 'low'
        END,
        NOW()
    FROM user_preferences up
    WHERE up.notification_enabled = true
    AND (up.location_name = NEW.location OR NEW.location = 'All')
    AND (up.alert_severity = 'all' OR up.alert_severity = NEW.severity);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically create notifications for new weather alerts
CREATE TRIGGER weather_alert_notification_trigger
    AFTER INSERT ON weather_alerts
    FOR EACH ROW
    EXECUTE FUNCTION create_weather_alert_notification();

-- =====================================================
-- MAINTENANCE FUNCTIONS
-- =====================================================

-- Function to clean up old weather data (keep last 90 days)
CREATE OR REPLACE FUNCTION cleanup_old_weather_data()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM weather_data 
    WHERE date_time < NOW() - INTERVAL '90 days';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Function to clean up old notifications (keep last 30 days)
CREATE OR REPLACE FUNCTION cleanup_old_notifications()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM notifications 
    WHERE created_at < NOW() - INTERVAL '30 days'
    AND is_read = true;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;
