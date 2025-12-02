from sqlalchemy import Column,Integer,Float,String,ForeignKey,DateTime
from sqlalchemy.orm import relationship
from datetime import datetime
from database import Base

class User(Base):
    __tablename__="users"

    id=Column(Integer,primary_key=True,index=True)
    ad=Column(String)
    soyad=Column(String)
    email=Column(String,unique=True,index=True)
    sifre=Column(String)

    predictions=relationship("Prediction",back_populates="user")

class Prediction(Base):
    __tablename__="predictions"

    id=Column(Integer,primary_key=True,index=True)
    user_id=Column(Integer,ForeignKey("users.id"))
    disease=Column(String,index=True)
    risk=Column(Float)
    details=Column(String)
    created_at=Column(DateTime,default=datetime.utcnow)
    
    user=relationship("User",back_populates="predictions")
