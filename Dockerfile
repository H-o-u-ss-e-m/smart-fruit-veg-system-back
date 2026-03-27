FROM python:3.10

WORKDIR /app

# ✅ AJOUT IMPORTANT
RUN apt-get update && apt-get install -y \
    libgl1 \
    libglib2.0-0

COPY . .

RUN pip install --upgrade pip
RUN pip install -r requirements.txt

CMD ["python", "run.py"]