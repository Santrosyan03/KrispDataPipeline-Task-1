import psycopg2
from datetime import datetime


def insert_user(cursor, username, password, country, native_language):
    query = """
                INSERT INTO users(username, password, country, native_language)
                VALUES (%s, %s, %s, %s)
                RETURNING id
            """
    cursor.execute(query, (username, password, country, native_language))
    return cursor.fetchone()[0]


def insert_session(cursor, start_time, end_time, session_type):
    query = """
                INSERT INTO sessions(start_time, end_time, session_type)
                VALUES (%s, %s, %s)
                RETURNING id
            """
    cursor.execute(query, (start_time, end_time, session_type))
    return cursor.fetchone()[0]


def insert_timezone(cursor, timezone_code, timezone_num):
    query = """
                INSERT INTO timezones(timezone_code, timezone_num)
                VALUES (%s, %s)
                RETURNING id
            """
    cursor.execute(query, (timezone_code, timezone_num))
    return cursor.fetchone()[0]


def insert_user_session_pivot(cursor, user_id, session_id, user_timezone_id, user_connected_timestamp,
                              user_disconnected_timestamp, talked_time, microphone_used, speaker_used):
    query = """
                INSERT INTO user_session_pivot(user_id, sessions_id, user_timezone_id, user_connected_timestamp, user_disconnected_timestamp, talked_time, microphone_used, speaker_used)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """
    cursor.execute(query, (
        user_id, session_id, user_timezone_id, user_connected_timestamp, user_disconnected_timestamp, talked_time,
        microphone_used, speaker_used)
    )


def insert_sentiment(cursor, user_session_id, timestamp_start, timestamp_end, sentiment_type):
    query = """
                INSERT INTO sentiments(user_session_id, timestamp_start, timestamp_end, sentiment_type)
                VALUES (%s, %s, %s, %s)
            """
    cursor.execute(query, (user_session_id, timestamp_start, timestamp_end, sentiment_type))


def insert_event(cursor, user_session_id, event_start, event):
    query = """
                INSERT INTO events(user_session_id, event_start, event)
                VALUES (%s, %s, %s)
            """
    cursor.execute(query, (user_session_id, event_start, event))


def show(cursor):
    query = """
                SELECT * FROM  users;
                SELECT * FROM  sessions;
                SELECT * FROM  timezones;
                SELECT * FROM  user_session_pivot;
                SELECT * FROM  sentiments;
                SELECT * FROM  events;                
            """
    cursor.execute(query)
    return cursor.fetchall()


def main():
    connection = psycopg2.connect(
        database="metrics_db",
        user="postgres",
        password="postgres",
        host="localhost",
        port="5432"
    )
    cursor = connection.cursor()

    user_id = insert_user(cursor, 'user_123', 'securepassword', 'USA', 'English')
    session_id = insert_session(cursor, datetime(2024, 8, 9, 12, 34, 56), datetime(2024, 8, 9, 13, 34, 56),
                                'conversation')
    timezone_id = insert_timezone(cursor, 'EST', -5)

    insert_user_session_pivot(cursor, user_id, session_id, timezone_id, datetime(2024, 8, 9, 12, 34, 56),
                              datetime(2024, 8, 9, 13, 34, 56), 150.5, 1.0, 1.0)
    insert_sentiment(cursor, 1, datetime(2024, 8, 9, 12, 34, 56), datetime(2024, 8, 9, 12, 54, 56), 'positive')
    insert_event(cursor, 1, datetime(2024, 8, 9, 12, 34, 56), 'call_started')

    print(show(cursor))

    connection.commit()
    cursor.close()
    connection.close()


if __name__ == '__main__':
    main()
