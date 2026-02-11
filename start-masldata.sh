#!/bin/bash

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════╗"
echo "║                                                        ║"
echo "║           MASLDatlas v2.0 - Quick Start                ║"
echo "║      FastAPI + React + Docker Stack                    ║"
echo "║                                                        ║"
echo "╚════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Vérifier Docker
echo -e "\n${YELLOW}🔍 Checking Docker...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker not found. Please install Docker first.${NC}"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Docker is not running. Please start Docker Desktop.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker is ready${NC}"

# Menu interactif
echo -e "\n${YELLOW}Choose how to start:${NC}"
echo "1) 🚀 Full stack with Docker (Production-like)"
echo "2) 💻 Development mode (Backend + Frontend separately)"
echo "3) 🧪 Run tests first"
echo "4) 📚 Show documentation"
echo "5) ❌ Exit"
echo ""
read -p "Enter your choice [1-5]: " choice

case $choice in
    1)
        echo -e "\n${BLUE}🚀 Starting backend with Docker...${NC}"
        echo -e "${YELLOW}ℹ️  Frontend is deployed on Vercel separately${NC}"
        
        # Build images
        echo -e "\n${YELLOW}📦 Building Docker images...${NC}"
        docker-compose build
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ Build failed${NC}"
            exit 1
        fi
        
        # Start services
        echo -e "\n${YELLOW}🎬 Starting services...${NC}"
        docker-compose up -d
        
        echo -e "\n${GREEN}✅ Backend services started successfully!${NC}"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${GREEN}🌐 Access URLs:${NC}"
        echo "  • Backend:   http://localhost:8000"
        echo "  • API Docs:  http://localhost:8000/api/docs"
        echo "  • Redis:     redis://localhost:6379"
        echo ""
        echo -e "${YELLOW}📊 Useful commands:${NC}"
        echo "  • View logs:    docker-compose logs -f"
        echo "  • Stop:         docker-compose down"
        echo "  • Restart:      docker-compose restart"
        echo ""
        echo -e "${BLUE}ℹ️  Frontend Deployment:${NC}"
        echo "  • Deploy to Vercel: cd frontend && vercel"
        echo "  • Local dev:        cd frontend && npm run dev"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        # Attendre que les services soient prêts
        echo -e "\n${YELLOW}⏳ Waiting for services to be ready...${NC}"
        sleep 5
        
        # Test health
        if curl -s http://localhost:8000/health | grep -q "healthy"; then
            echo -e "${GREEN}✅ Backend is healthy${NC}"
        else
            echo -e "${RED}⚠️  Backend may not be ready yet (check logs)${NC}"
        fi
        
        echo -e "\n${GREEN}🎉 Backend is ready!${NC}"
        ;;
        
    2)
        echo -e "\n${BLUE}💻 Starting development mode...${NC}"
        
        echo -e "\n${YELLOW}This will open 2 terminal windows:${NC}"
        echo "  1. Backend (FastAPI on port 8000)"
        echo "  2. Frontend (Vite dev server on port 5173)"
        echo ""
        read -p "Press Enter to continue..."
        
        # Backend
        echo -e "\n${YELLOW}🐍 Starting backend...${NC}"
        osascript -e 'tell app "Terminal"
            do script "cd '"$(pwd)/backend"' && echo \"🐍 Backend Server - FastAPI\" && echo \"\" && uvicorn app.main:app --reload"
        end tell'
        
        # Frontend
        echo -e "${YELLOW}⚛️  Starting frontend...${NC}"
        osascript -e 'tell app "Terminal"
            do script "cd '"$(pwd)/frontend"' && echo \"⚛️  Frontend Server - Vite\" && echo \"\" && npm run dev"
        end tell'
        
        echo -e "\n${GREEN}✅ Development servers starting in new terminals${NC}"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${GREEN}🌐 Access URLs:${NC}"
        echo "  • Frontend:  http://localhost:5173 (Vite)"
        echo "  • Backend:   http://localhost:8000"
        echo "  • API Docs:  http://localhost:8000/api/docs"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        ;;
        
    3)
        echo -e "\n${BLUE}🧪 Running tests...${NC}"
        
        echo -e "\n${YELLOW}1. Backend validation${NC}"
        cd backend && python3 test_quick.py
        
        echo -e "\n${YELLOW}2. Backend Docker test${NC}"
        cd .. && ./test-docker.sh
        
        echo -e "\n${YELLOW}3. Frontend build test${NC}"
        cd frontend && npm run build
        
        echo -e "\n${GREEN}✅ All tests completed! See TEST_REPORT.md for details${NC}"
        ;;
        
    4)
        echo -e "\n${BLUE}📚 Documentation:${NC}"
        echo ""
        echo "Main documentation files:"
        echo "  • README.v2.md          - Complete project documentation"
        echo "  • MIGRATION_GUIDE.md    - Migration from Shiny to FastAPI"
        echo "  • QUICKSTART.md         - Quick start tutorials"
        echo "  • TEST_REPORT.md        - Test results and validation"
        echo ""
        echo "API Documentation (when running):"
        echo "  • http://localhost:8000/api/docs     - Swagger UI"
        echo "  • http://localhost:8000/api/redoc    - ReDoc"
        echo ""
        
        read -p "Open README.v2.md? [y/N] " open_readme
        if [[ $open_readme =~ ^[Yy]$ ]]; then
            open README.v2.md || cat README.v2.md
        fi
        ;;
        
    5)
        echo -e "\n${YELLOW}👋 Goodbye!${NC}"
        exit 0
        ;;
        
    *)
        echo -e "\n${RED}❌ Invalid choice${NC}"
        exit 1
        ;;
esac
