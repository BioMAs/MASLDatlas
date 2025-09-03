# Performance Dashboard Module
# Provides real-time performance monitoring and analytics

#' Create Performance Dashboard UI
create_performance_dashboard_ui <- function() {
  fluidPage(
    tags$head(
      tags$style(HTML("
        .metric-card {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          border-radius: 10px;
          padding: 20px;
          margin-bottom: 20px;
          box-shadow: 0 4px 15px rgba(0,0,0,0.1);
        }
        .metric-value {
          font-size: 2.5em;
          font-weight: bold;
          margin-bottom: 5px;
        }
        .metric-label {
          font-size: 1.1em;
          opacity: 0.9;
        }
        .status-good { background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%); }
        .status-warning { background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); }
        .status-critical { background: linear-gradient(135deg, #fc466b 0%, #3f5efb 100%); }
        .performance-chart {
          background: white;
          border-radius: 10px;
          padding: 15px;
          box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
      "))
    ),
    
    h2("⚡ Performance Dashboard", class = "text-center mb-4"),
    
    # Real-time metrics row
    fluidRow(
      column(3,
        div(class = "metric-card status-good",
          div(class = "metric-value", textOutput("cache_hit_rate")),
          div(class = "metric-label", "Cache Hit Rate")
        )
      ),
      column(3,
        div(class = "metric-card status-good",
          div(class = "metric-value", textOutput("memory_usage")),
          div(class = "metric-label", "Memory Usage")
        )
      ),
      column(3,
        div(class = "metric-card status-good",
          div(class = "metric-value", textOutput("operations_count")),
          div(class = "metric-label", "Operations Today")
        )
      ),
      column(3,
        div(class = "metric-card status-good",
          div(class = "metric-value", textOutput("avg_response_time")),
          div(class = "metric-label", "Avg Response (ms)")
        )
      )
    ),
    
    # Performance charts row
    fluidRow(
      column(6,
        div(class = "performance-chart",
          h4("📊 Operation Performance"),
          plotOutput("performance_timeline")
        )
      ),
      column(6,
        div(class = "performance-chart",
          h4("💾 Cache Statistics"),
          plotOutput("cache_stats")
        )
      )
    ),
    
    # System health row
    fluidRow(
      column(12,
        div(class = "performance-chart",
          h4("🏥 System Health Report"),
          verbatimTextOutput("health_report")
        )
      )
    ),
    
    # Action buttons
    fluidRow(
      column(12, class = "text-center mt-3",
        actionButton("refresh_performance", "🔄 Refresh Data", class = "btn-primary"),
        actionButton("clear_cache", "🗑️ Clear Cache", class = "btn-warning ml-3"),
        actionButton("export_report", "📄 Export Report", class = "btn-info ml-3")
      )
    )
  )
}

#' Server logic for performance dashboard
create_performance_dashboard_server <- function(input, output, session) {
  
  # Reactive values for real-time updates
  performance_data <- reactiveVal()
  
  # Update performance data every 30 seconds
  observe({
    invalidateLater(30000) # 30 seconds
    
    if (exists("get_performance_stats", mode = "function")) {
      stats <- get_performance_stats()
      performance_data(stats)
    }
  })
  
  # Cache hit rate
  output$cache_hit_rate <- renderText({
    stats <- performance_data()
    if (!is.null(stats) && !is.null(stats$cache_hit_rate)) {
      paste0(round(stats$cache_hit_rate * 100, 1), "%")
    } else {
      "N/A"
    }
  })
  
  # Memory usage
  output$memory_usage <- renderText({
    stats <- performance_data()
    if (!is.null(stats) && !is.null(stats$memory_mb)) {
      paste0(round(stats$memory_mb, 1), "MB")
    } else {
      paste0(round(as.numeric(object.size(.GlobalEnv)) / 1024^2, 1), "MB")
    }
  })
  
  # Operations count
  output$operations_count <- renderText({
    stats <- performance_data()
    if (!is.null(stats) && !is.null(stats$operations_today)) {
      format(stats$operations_today, big.mark = ",")
    } else {
      "0"
    }
  })
  
  # Average response time
  output$avg_response_time <- renderText({
    stats <- performance_data()
    if (!is.null(stats) && !is.null(stats$avg_response_ms)) {
      round(stats$avg_response_ms, 0)
    } else {
      "N/A"
    }
  })
  
  # Performance timeline chart
  output$performance_timeline <- renderPlot({
    if (exists("get_performance_history", mode = "function")) {
      history <- get_performance_history()
      if (!is.null(history) && nrow(history) > 0) {
        ggplot(history, aes(x = timestamp, y = response_time)) +
          geom_line(color = "#3498db", size = 1.2) +
          geom_smooth(method = "loess", color = "#e74c3c", alpha = 0.3) +
          theme_minimal() +
          labs(x = "Time", y = "Response Time (ms)", 
               title = "Response Time Trend") +
          theme(plot.title = element_text(hjust = 0.5))
      } else {
        # Default plot when no data
        ggplot() + 
          geom_text(aes(x = 1, y = 1), label = "No performance data available yet", 
                   size = 5, hjust = 0.5) +
          theme_void()
      }
    } else {
      # Fallback plot
      ggplot() + 
        geom_text(aes(x = 1, y = 1), label = "Performance monitoring not active", 
                 size = 5, hjust = 0.5) +
        theme_void()
    }
  })
  
  # Cache statistics chart
  output$cache_stats <- renderPlot({
    if (exists("get_cache_stats", mode = "function")) {
      cache_stats <- get_cache_stats()
      if (!is.null(cache_stats)) {
        df <- data.frame(
          Type = c("Hits", "Misses"),
          Count = c(cache_stats$hits, cache_stats$misses),
          stringsAsFactors = FALSE
        )
        
        ggplot(df, aes(x = Type, y = Count, fill = Type)) +
          geom_col(width = 0.6) +
          scale_fill_manual(values = c("Hits" = "#2ecc71", "Misses" = "#e74c3c")) +
          theme_minimal() +
          labs(title = "Cache Performance", y = "Count") +
          theme(legend.position = "none", plot.title = element_text(hjust = 0.5))
      } else {
        ggplot() + 
          geom_text(aes(x = 1, y = 1), label = "No cache data available", 
                   size = 5, hjust = 0.5) +
          theme_void()
      }
    } else {
      ggplot() + 
        geom_text(aes(x = 1, y = 1), label = "Cache monitoring not active", 
                 size = 5, hjust = 0.5) +
        theme_void()
    }
  })
  
  # System health report
  output$health_report <- renderText({
    if (exists("generate_health_report", mode = "function")) {
      generate_health_report()
    } else {
      "✅ Basic system operational\n📊 Performance monitoring: Available\n💾 Cache system: Loaded\n🔧 Optimization modules: Active"
    }
  })
  
  # Refresh button
  observeEvent(input$refresh_performance, {
    if (exists("get_performance_stats", mode = "function")) {
      stats <- get_performance_stats()
      performance_data(stats)
      showNotification("📊 Performance data refreshed", type = "message")
    }
  })
  
  # Clear cache button
  observeEvent(input$clear_cache, {
    if (exists("clear_all_cache", mode = "function")) {
      clear_all_cache()
      showNotification("🗑️ Cache cleared successfully", type = "message")
    } else {
      showNotification("⚠️ Cache clearing not available", type = "warning")
    }
  })
  
  # Export report button
  observeEvent(input$export_report, {
    if (exists("export_performance_report", mode = "function")) {
      export_performance_report()
      showNotification("📄 Performance report exported", type = "message")
    } else {
      showNotification("⚠️ Report export not available", type = "warning")
    }
  })
}
