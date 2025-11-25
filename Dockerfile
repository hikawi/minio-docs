FROM python:3.14-alpine AS builder
WORKDIR /app

RUN apk add --no-cache coreutils nodejs npm curl make bash

# Install dependencies for Node
COPY package.json package-lock.json ./
RUN npm ci

# Copy gulpfile and build CSS
COPY gulpfile.js .
COPY ./source ./source
RUN ls /app && npm run build

# Install python deps
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Start copying files over for final build
COPY . .

# Build the server
# This is needed because the ass Makefile needs both NPM and PIP
ENV SYNC_SDK=true
RUN make mindocs

FROM python:3.14-alpine AS prod
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY --from=builder /app/build ./build

EXPOSE 8000
CMD ["python", "-m", "http.server", "--directory", "./build/mindocs/html"]

