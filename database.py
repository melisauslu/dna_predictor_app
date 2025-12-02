from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker


DB_SERVER = r"DESKTOP-G01B4G7\SQLEXPRESS"
DB_NAME = "HealthRiskDB"
DB_DRIVER = "ODBC Driver 17 for SQL Server"

odbc_str = (
    f"DRIVER={{{DB_DRIVER}}};"
    f"SERVER={DB_SERVER};"
    f"DATABASE={DB_NAME};"
    f"Trusted_Connection=yes;"
)

DATABASE_URL = f"mssql+pyodbc:///?odbc_connect={odbc_str}"


engine = create_engine(DATABASE_URL, fast_executemany=True)


SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


Base = declarative_base()


def init_db():
    Base.metadata.create_all(bind=engine)
    print("✅ Veritabanı tabloları başarıyla oluşturuldu.")


if __name__ == "__main__":
    init_db()
