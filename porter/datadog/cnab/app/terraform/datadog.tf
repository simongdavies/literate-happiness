variable datadog_api_key {}
variable  datadog_app_key {}
variable  dashboard_name {}

provider "datadog" {
  api_key = "${var.datadog_api_key}"
  app_key = "${var.datadog_app_key}"
}

resource "datadog_dashboard" "ordered_dashboard" {
  title         = "${var.dashboard_name}"
  description   = "Created using ARM and CNAB"
  layout_type   = "ordered"
  is_read_only  = true

  widget {
    alert_graph_definition {
      alert_id = "895605"
      viz_type = "timeseries"
      title = "Widget Title"
      time = {
        live_span = "1h"
      }
    }
  }

  widget {
    alert_value_definition {
      alert_id = "895605"
      precision = 3
      unit = "b"
      text_align = "center"
      title = "Widget Title"
    }
  }

  widget {
    alert_value_definition {
      alert_id = "895605"
      precision = 3
      unit = "b"
      text_align = "center"
      title = "Widget Title"
    }
  }

  widget {
    change_definition {
      request {
        q = "avg:system.load.1{env:staging} by {account}"
        change_type = "absolute"
        compare_to = "week_before"
        increase_good = true
        order_by = "name"
        order_dir = "desc"
        show_present = true
      }
      title = "Widget Title"
      time = {
        live_span = "1h"
      }
    }
  }

  widget {
    distribution_definition {
      request {
        q = "avg:system.load.1{env:staging} by {account}"
        style {
          palette = "warm"
        }
      }
      title = "Widget Title"
      time = {
        live_span = "1h"
      }
    }
  }

  widget {
    heatmap_definition {
      request {
        q = "avg:system.load.1{env:staging} by {account}"
        style {
          palette = "warm"
        }
      }
      yaxis {
        min = 1
        max = 2
        include_zero = true
        scale = "sqrt"
      }
      title = "Widget Title"
      time = {
        live_span = "1h"
      }
    }
  }

 
  widget {
    note_definition {
      content = "note text"
      background_color = "pink"
      font_size = "14"
      text_align = "center"
      show_tick = true
      tick_edge = "left"
      tick_pos = "50%"
    }
  }

  widget {
    query_value_definition {
      request {
        q = "avg:system.load.1{env:staging} by {account}"
        aggregator = "sum"
        conditional_formats {
          comparator = "<"
          value = "2"
          palette = "white_on_green"
        }
        conditional_formats {
          comparator = ">"
          value = "2.2"
          palette = "white_on_red"
        }
      }
      autoscale = true
      custom_unit = "xx"
      precision = "4"
      text_align = "right"
      title = "Widget Title"
      time = {
        live_span = "1h"
      }
    }
  }

  widget {
    scatterplot_definition {
      request {
        x {
          q = "avg:system.cpu.user{*} by {service, account}"
          aggregator = "max"
        }
        y {
          q = "avg:system.mem.used{*} by {service, account}"
          aggregator = "min"
        }
      }
      color_by_groups = ["account", "apm-role-group"]
      xaxis {
        include_zero = true
        label = "x"
        min = "1"
        max = "2000"
        scale = "pow"
      }
      yaxis {
        include_zero = false
        label = "y"
        min = "5"
        max = "2222"
        scale = "log"
      }
      title = "Widget Title"
      time = {
        live_span = "1h"
      }
    }
  }

  widget {
    timeseries_definition {
      request {
        q= "avg:system.cpu.user{app:general} by {env}"
        display_type = "line"
        style {
          palette = "warm"
          line_type = "dashed"
          line_width = "thin"
        }
        metadata {
          expression = "avg:system.cpu.user{app:general} by {env}"
          alias_name = "Alpha"
        }
      }
      request {
        log_query {
          index = "mcnulty"
          compute = {
            aggregation = "avg"
            facet = "@duration"
            interval = 5000
          }
          search = {
            query = "status:info"
          }
          group_by {
            facet = "host"
            limit = 10
            sort = {
              aggregation = "avg"
              order = "desc"
              facet = "@duration"
            }
          }
        }
        display_type = "area"
      }
      request {
        apm_query {
          index = "apm-search"
          compute = {
            aggregation = "avg"
            facet = "@duration"
            interval = 5000
          }
          search = {
            query = "type:web"
          }
          group_by {
            facet = "resource_name"
            limit = 50
            sort = {
              aggregation = "avg"
              order = "desc"
              facet = "@string_query.interval"
            }
          }
        }
        display_type = "bars"
      }
      request {
        process_query {
          metric = "process.stat.cpu.total_pct"
          search_by = "error"
          filter_by = ["active"]
          limit = 50
        }
        display_type = "area"
      }
      marker {
        display_type = "error dashed"
        label = " z=6 "
        value = "y = 4"
      }
      marker {
        display_type = "ok solid"
        value = "10 < y < 999"
        label = " x=8 "
      }
      title = "Widget Title"
      time = {
        live_span = "1h"
      }
    }
  }

  widget {
    toplist_definition {
      request {
        q= "avg:system.cpu.user{app:general} by {env}"
        conditional_formats {
          comparator = "<"
          value = "2"
          palette = "white_on_green"
        }
        conditional_formats {
          comparator = ">"
          value = "2.2"
          palette = "white_on_red"
        }
      }
      title = "Widget Title"
    }
  }

  widget {
    group_definition {
      layout_type = "ordered"
      title = "Group Widget"

      widget {
        note_definition {
          content = "cluster note widget"
          background_color = "pink"
          font_size = "14"
          text_align = "center"
          show_tick = true
          tick_edge = "left"
          tick_pos = "50%"
        }
      }

      widget {
        alert_graph_definition {
          alert_id = "123"
          viz_type = "toplist"
          title = "Alert Graph"
          time = {
            live_span = "1h"
          }
        }
      }
    }
  }
}