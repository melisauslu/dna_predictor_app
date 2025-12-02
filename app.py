from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from sqlalchemy.orm import Session
from database import SessionLocal, init_db
from models import User, Prediction
import bcrypt
import pickle
import os


app = FastAPI(title="DNA Hastalık Tahmin API")

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


init_db()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


class DiabetesInput(BaseModel):
    Pregnancies: int
    Glucose: float
    BloodPressure: float
    SkinThickness: float
    Insulin: float
    BMI: float
    DiabetesPedigreeFunction: float
    Age: int

class HeartInput(BaseModel):
    age: int
    sex: int
    chest_pain_type: int
    resting_bp_s: float
    cholesterol: float
    fasting_blood_sugar: int
    resting_ecg: int
    max_heart_rate: float
    exercise_angina: int
    oldpeak: float
    ST_slope: int

class CancerInput(BaseModel):
    radius_mean: float
    texture_mean: float
    perimeter_mean: float
    area_mean: float
    smoothness_mean: float
    compactness_mean: float
    concavity_mean: float
    concave_points_mean: float
    symmetry_mean: float
    fractal_dimension_mean: float
    radius_se: float
    texture_se: float
    perimeter_se: float
    area_se: float
    smoothness_se: float
    compactness_se: float
    concavity_se: float
    concave_points_se: float
    symmetry_se: float
    fractal_dimension_se: float
    radius_worst: float
    texture_worst: float
    perimeter_worst: float
    area_worst: float
    smoothness_worst: float
    compactness_worst: float
    concavity_worst: float
    concave_points_worst: float
    symmetry_worst: float
    fractal_dimension_worst: float


models_dir = os.path.join(os.path.dirname(__file__), "models")

with open(os.path.join(models_dir, "diabetes_model.pkl"), "rb") as f:
    diabetes_model = pickle.load(f)

with open(os.path.join(models_dir, "heart_model.pkl"), "rb") as f:
    heart_model = pickle.load(f)

with open(os.path.join(models_dir, "cancer_model.pkl"), "rb") as f:
    cancer_model = pickle.load(f)

cancer_features_path = os.path.join(models_dir, "cancer_features.pkl")
if os.path.exists(cancer_features_path):
    with open(cancer_features_path, "rb") as f:
        cancer_features = pickle.load(f)
    print("✅ Cancer features yüklendi:", cancer_features_path)
else:
    cancer_features = None
    print("Cancer features dosyası bulunamadı")


@app.get("/")
def home():
    return {"message": "DNA Hastalık Tahmin API çalışıyor!"}


@app.post("/predict/diabetes")
def predict_diabetes(data: DiabetesInput):
    features = [[
        data.Pregnancies,
        data.Glucose,
        data.BloodPressure,
        data.SkinThickness,
        data.Insulin,
        data.BMI,
        data.DiabetesPedigreeFunction,
        data.Age
    ]]
    prob = diabetes_model.predict_proba(features)[0][1] * 100
    return {"diabetes_risk": round(prob, 2)}

@app.post("/predict/heart")
def predict_heart(data: HeartInput):
    features = [[
        data.age,
        data.sex,
        data.chest_pain_type,
        data.resting_bp_s,
        data.cholesterol,
        data.fasting_blood_sugar,
        data.resting_ecg,
        data.max_heart_rate,
        data.exercise_angina,
        data.oldpeak,
        data.ST_slope
    ]]
    prob = heart_model.predict_proba(features)[0][1] * 100
    return {"heart_risk": round(prob, 2)}

@app.post("/predict/cancer")
def predict_cancer(data: CancerInput):
    if cancer_features is None:
        return {"error": "Cancer features dosyası bulunamadı."}

    features = [[getattr(data, feat) for feat in cancer_features]]
    prediction = cancer_model.predict(features)[0]
    prob = cancer_model.predict_proba(features)[0][1] * 100

    return {
        "prediction": int(prediction),
        "cancer_risk": round(prob, 2)
    }


class RegisterInput(BaseModel):
    ad: str
    soyad: str
    email: str
    sifre: str

class LoginInput(BaseModel):
    email: str
    sifre: str


@app.post("/register")
def register_user(data: RegisterInput, db: Session = Depends(get_db)):
    existing_user = db.query(User).filter(User.email == data.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Bu e-posta zaten kayıtlı."
        )

    hashed_pw = bcrypt.hashpw(data.sifre.encode('utf-8'), bcrypt.gensalt())
    new_user = User(
        ad=data.ad,
        soyad=data.soyad,
        email=data.email,
        sifre=hashed_pw.decode('utf-8')
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return {"message": "Kullanıcı başarıyla kaydedildi", "user_id": new_user.id}


@app.post("/login")
def login_user(data: LoginInput, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == data.email).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Kullanıcı bulunamadı."
        )

    if not bcrypt.checkpw(data.sifre.encode('utf-8'), user.sifre.encode('utf-8')):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Yanlış şifre."
        )

    return {"message": f"Hoş geldiniz, {user.ad} {user.soyad}!"}

