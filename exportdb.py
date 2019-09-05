from contextlib import contextmanager
import sqlite3

@contextmanager
def openSQLite(filename):
    connection = sqlite3.connect(filename)
    try:
        yield connection
    finally:
        if connection:
            connection.close()

with openSQLite('lego.sqlite') as connection:
    cursor = connection.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS legos (
            id integer PRIMARY KEY,
            name text NOT NULL
        );
    """)
    cursor.execute("""
        INSERT INTO legos (
            id,
            name
        ) VALUES (
            1,
            'brick'
        );
    """)
    cursor.execute(
        """
        INSERT INTO legos (id, name) VALUES (?, ?);
        """,
        [2, 'slope']
    )
    connection.commit()
