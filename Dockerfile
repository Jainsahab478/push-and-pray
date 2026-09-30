FROM python:3.10-slim

WORKDIR /webapp

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt \
    && useradd --create-home --uid 1000 appuser

COPY . .

RUN chown -R appuser:appuser /webapp

USER appuser

EXPOSE 9000

CMD ["python3", "app.py"]
