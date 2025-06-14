FROM cirrusci/flutter:3.19.6

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./

RUN flutter pub get

COPY . .

# Construye el proyecto web
RUN flutter build web

ENV PATH="/root/.pub-cache/bin:${PATH}"

# Usa un servidor simple para servirlo (opcional: puedes usar nginx o dhttpd)
RUN pub global activate dhttpd

EXPOSE 8080

# Sirve el contenido web en el puerto 8080
CMD ["dhttpd", "--path", "build/web", "--port", "8080"]
