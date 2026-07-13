FROM python:3.12.4-slim
WORKDIR /app
COPY app.py .
RUN useradd --create-home appuser && chown -R appuser /app
USER appuser
EXPOSE 8080
HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen(\"http://localhost:8080/health\")" || exit 1
CMD ["python", "app.py"]
