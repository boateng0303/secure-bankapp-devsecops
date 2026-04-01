FROM python:3.11-slim

WORKDIR /app

COPY autoremediation.py .

RUN pip install fastapi uvicorn pydantic

EXPOSE 8000

CMD ["uvicorn", "autoremediation:app", "--host", "0.0.0.0", "--port", "8000"]
