# Secure Banking App

Secure Banking App gives you a simple, fast, protected banking experience. You run it with an Angular frontend and a Spring Boot backend. The system helps you test modern DevSecOps skills through a realistic workflow.

## Features
- User registration and login with JWT authentication.
- Role based access control.
- Account dashboard with balances and recent transactions.
- Secure API calls through HTTPS and input validation.
- Angular UI served behind Nginx.
- Spring Boot backend with security filters and strong defaults.
- CI and CD pipeline with code scanning, dependency checks, and container scanning.
- Kubernetes ready container images.

## Technology stack
- Angular 17 frontend.
- Spring Boot 3 backend.
- PostgreSQL database.
- Nginx static hosting.
- Docker and Kubernetes deployment.
- GitHub Actions pipeline.

## Project structure
- banking-app-frontend contains the Angular UI.
- banking-app-backend contains the Spring Boot service.
- manifests contains Kubernetes deployment files.
- docker contains Dockerfiles and Nginx configs.

## How to run locally
- Install Node and Java 17.
- Install Angular CLI.
- Run npm install in the frontend folder.
- Run ng serve to start the UI.
- Run mvn spring-boot:run in the backend folder.
- Access the app at http://localhost:4200.

## Security approach
- Input validation on every request.
- Strong password rules.
- JWT based sessions with short lifetimes.
- Security headers in Nginx.
- Dependency checks through GitHub Actions.
- Container scans for every image.
