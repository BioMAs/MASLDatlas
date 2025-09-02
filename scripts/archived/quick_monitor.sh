#!/bin/bash
# Quick monitoring script

echo "🔍 MASLDatlas Quick Status Check"
echo "================================"

# Check if application is running
if curl -f -s http://localhost:3838 > /dev/null 2>&1; then
    echo "✅ Application: Running"
else
    echo "❌ Application: Not responding"
fi

# Check Docker containers
if command -v docker &> /dev/null; then
    if docker ps | grep -q masldatlas; then
        echo "✅ Docker: Container running"
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep masldatlas
    else
        echo "⚠️ Docker: No containers running"
    fi
fi

# Check logs
echo ""
echo "📝 Recent logs:"
tail -n 5 logs/*.log 2>/dev/null | head -10 || echo "No recent logs"

# Check disk space
echo ""
echo "💾 Disk space:"
df -h . | tail -1 | awk '{print "Available: " $4 " (" $5 " used)"}'
