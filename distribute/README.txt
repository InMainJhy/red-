========================================
   时序人格局 (TimePersona) Setup Guide
========================================

[Prerequisites]
1. Install Docker Desktop (https://www.docker.com/products/docker-desktop)
   - Download and run Docker Desktop Installer
   - After install, start Docker Desktop and wait for the green status icon

========================================

[Option 1: One-Click Start (Recommended)]

1. Extract this ZIP to any directory (avoid Chinese characters in path)

2. Double-click start.bat
   - First run will build Docker images (~3-5 minutes)
   - Browser will open automatically

3. Visit http://localhost:8080 to use the app

4. When done, run stop.bat to stop all services

========================================

[Option 2: Command Line]

docker compose up -d --build

========================================

[Port Reference]

  8080 - Web application (browser access)
 3030  - API endpoint
54329  - PostgreSQL database (no need to access)

========================================

[Troubleshooting]

Q: start.bat shows "docker is not a command"
A: Make sure Docker Desktop is installed and running. Restart your computer.

Q: "Port already in use"
A: Edit docker-compose.yml, change:
    web: "8080:80" -> "8081:80"
    backend: "3030:3030" -> "3031:3031"
   Then re-run start.bat

Q: Page shows "Cannot connect to backend"
A: Wait 10 seconds and refresh. Backend needs time to initialize the database.

Q: How to view backend logs?
A: Open Docker Desktop -> Containers -> time-persona-backend -> Logs

========================================

[HarmonyOS Phone Install]

1. Connect phone to PC (enable Developer Mode + USB Debugging)

2. Navigate to harmony_hap folder and install:
   hdc.exe install entry-default-signed.hap

3. Open the app, go to Settings and enter:
   API URL: http://<PC-IP>:3030
   (Find your PC IP: cmd -> ipconfig -> IPv4 Address)

========================================

[Change AI Model]

Edit docker-compose.yml, find:
  TARGET_MODEL: gpt-5.4
Change to your model name, e.g. glm-5 or claude-opus-4-6

========================================
