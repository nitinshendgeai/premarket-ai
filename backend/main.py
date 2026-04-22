from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from api.routes import router
import uvicorn

app = FastAPI(
    title="Pre-Market Trading Assistant",
    version="2.0.0",
)

# CORS — allow all origins (credentials must be False with wildcard)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router, prefix="")

@app.get("/")
def root():
    return {"status": "running", "service": "Pre-Market Trading Assistant v2"}

@app.get("/health")
def health_check():
    return {"status": "healthy", "version": "2.0.0"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
