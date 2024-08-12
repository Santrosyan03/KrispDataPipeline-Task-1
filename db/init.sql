CREATE TABLE users(
    id SERIAL PRIMARY KEY,
    username varchar(255),
    password varchar(255),
    country varchar(255),
    native_language varchar(255)
);

CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_country ON users(country);
CREATE INDEX idx_users_native_language ON users(native_language);

CREATE INDEX idx_users_country_native_language ON users(country, native_language);


CREATE TABLE sessions(
    id SERIAL PRIMARY KEY,
    start_time timestamp,
    end_time timestamp,
    session_type varchar(255)
);

CREATE INDEX idx_sessions_start_time ON sessions(start_time);
CREATE INDEX idx_sessions_end_time ON sessions(end_time);
CREATE INDEX idx_sessions_session_type ON sessions(session_type);

CREATE INDEX idx_sessions_start_end_time ON sessions(start_time, end_time);


CREATE TABLE timezones(
    id SERIAL PRIMARY KEY,
    timezone_code varchar,
    timezone_num  int
);

CREATE UNIQUE INDEX idx_timezones_unique_timezone_code ON timezones(timezone_code);

CREATE INDEX idx_timezones_timezone_code ON timezones(timezone_code);


CREATE TABLE user_session_pivot(
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id),
    sessions_id INT REFERENCES sessions(id),
    user_timezone_id INT REFERENCES timezones(id),
    user_connected_timestamp timestamp with time zone,
    user_disconnected_timestamp timestamp with time zone,
    talked_time float,
    microphone_used float,
    speaker_used float
);

CREATE INDEX idx_user_session_pivot_user_id ON user_session_pivot(user_id);
CREATE INDEX idx_user_session_pivot_sessions_id ON user_session_pivot(sessions_id);
CREATE INDEX idx_user_session_pivot_user_timezone_id ON user_session_pivot(user_timezone_id);
CREATE INDEX idx_user_session_pivot_user_connected_timestamp ON user_session_pivot(user_connected_timestamp);
CREATE INDEX idx_user_session_pivot_user_disconnected_timestamp ON user_session_pivot(user_disconnected_timestamp);

CREATE INDEX idx_user_session_pivot_user_sessions_id ON user_session_pivot(user_id, sessions_id);


CREATE TABLE sentiments(
    id SERIAL PRIMARY KEY,
    user_session_id INT REFERENCES user_session_pivot(id),
    timestamp_start timestamp with time zone,
    timestamp_end timestamp with time zone,
    sentiment_type varchar
);

CREATE INDEX idx_sentiments_timestamp_start ON sentiments(timestamp_start);
CREATE INDEX idx_sentiments_timestamp_end ON sentiments(timestamp_end);
CREATE INDEX idx_sentiments_sentiment_type ON sentiments(sentiment_type);

CREATE INDEX idx_sentiments_user_session_timestamp ON sentiments(user_session_id, timestamp_start);


CREATE TABLE events(
    id SERIAL PRIMARY KEY,
    user_session_id INT REFERENCES user_session_pivot(id),
    event_start timestamp with time zone,
    event varchar
);

CREATE INDEX idx_events_event_start ON events(event_start);
CREATE INDEX idx_events_event ON events(event);

CREATE INDEX idx_events_user_session_event_start ON events(user_session_id, event_start);


------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION convert_to_float_trigger()
    RETURNS TRIGGER AS $$
BEGIN
    -- Convert talked_time to float if it is not null
    IF NEW.talked_time IS NOT NULL THEN
        NEW.talked_time := NEW.talked_time::float;
    END IF;

    -- Convert microphone_used to float if it is not null
    IF NEW.microphone_used IS NOT NULL THEN
        NEW.microphone_used := NEW.microphone_used::float;
    END IF;

    -- Convert speaker_used to float if it is not null
    IF NEW.speaker_used IS NOT NULL THEN
        NEW.speaker_used := NEW.speaker_used::float;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER convert_to_float_before_insert_or_update
    BEFORE INSERT OR UPDATE ON user_session_pivot
    FOR EACH ROW
EXECUTE FUNCTION convert_to_float_trigger();
------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_timestamp()
    RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

ALTER TABLE users ADD COLUMN updated_at INTERVAL;

CREATE TRIGGER update_users_timestamp
    BEFORE UPDATE ON users
    FOR EACH ROW
EXECUTE FUNCTION update_timestamp();
------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION calculate_session_duration()
    RETURNS TRIGGER AS $$
BEGIN
    NEW.session_duration = NEW.end_time - NEW.start_time;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

ALTER TABLE sessions ADD COLUMN session_duration INTERVAL;

CREATE TRIGGER set_session_duration
    BEFORE UPDATE ON sessions
    FOR EACH ROW
    WHEN (NEW.end_time IS NOT NULL)
EXECUTE FUNCTION calculate_session_duration();
------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION delete_related_sessions()
    RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM user_session_pivot WHERE user_id = OLD.id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER cascade_delete_user_session_pivot
    BEFORE DELETE ON users
    FOR EACH ROW
EXECUTE FUNCTION delete_related_sessions();
------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION prevent_overlapping_user_sessions()
    RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM user_session_pivot
        WHERE user_id = NEW.user_id
          AND (
            (NEW.user_connected_timestamp, NEW.user_disconnected_timestamp)
                OVERLAPS
            (user_connected_timestamp, user_disconnected_timestamp)
            )
    ) THEN
        RAISE EXCEPTION 'User cannot have overlapping sessions.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_no_overlap_user_sessions
    BEFORE INSERT OR UPDATE ON user_session_pivot
    FOR EACH ROW
EXECUTE FUNCTION prevent_overlapping_user_sessions();

------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION validate_sentiment_duration()
    RETURNS TRIGGER AS $$
BEGIN
    IF NEW.timestamp_end <= NEW.timestamp_start THEN
        RAISE EXCEPTION 'timestamp_end must be after timestamp_start';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_sentiment_duration
    BEFORE INSERT OR UPDATE ON sentiments
    FOR EACH ROW
EXECUTE FUNCTION validate_sentiment_duration();
------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_user_session_timezone()
    RETURNS TRIGGER AS $$
BEGIN
    UPDATE user_session_pivot
    SET user_timezone_id = NEW.id
    WHERE user_timezone_id = OLD.id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_session_timezone
    AFTER UPDATE ON timezones
    FOR EACH ROW
EXECUTE FUNCTION update_user_session_timezone();
------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION prevent_duplicate_timezones()
    RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM timezones WHERE timezone_code = NEW.timezone_code
    ) THEN
        RAISE EXCEPTION 'Timezone code % already exists. Insert prevented.', NEW.timezone_code;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_unique_timezone_code
    BEFORE INSERT OR UPDATE ON timezones
    FOR EACH ROW
EXECUTE FUNCTION prevent_duplicate_timezones();

