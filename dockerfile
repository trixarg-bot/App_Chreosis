FROM cirrusci/flutter:3.19.6

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./

RUN flutter pub get

COPY . .

CMD ["flutter", "run"]
