start_date <- as.Date("2020-01-08")

fluidPage(
  titlePanel("Dates and date ranges"),

  column(4, wellPanel(
    dateInput('date',
      label = 'Date input: yyyy-mm-dd',
      value = start_date
    ),

    dateInput('date2',
      label = paste('Date input 2: string for starting value,',
        'dd/mm/yy format, locale ja, range limited,',
        'week starts on day 1 (Monday)'),
      value = as.character(start_date),
      min = start_date - 5, max = start_date + 5,
      format = "dd/mm/yy",
      startview = 'year', language = 'zh-TW', weekstart = 1
    ),

    dateRangeInput('dateRange',
      label = 'Date range input: yyyy-mm-dd',
      start = start_date - 2, end = start_date + 2
    ),

    dateRangeInput('dateRange2',
      label = paste('Date range input 2: range is limited,',
       'dd/mm/yy, language: fr, week starts on day 1 (Monday),',
       'separator is "-", start view is year'),
      start = start_date - 3, end = start_date + 3,
      min = start_date - 10, max = start_date + 10,
      separator = " - ", format = "dd/mm/yy",
      startview = 'year', language = 'fr', weekstart = 1
    )
  )),

  column(6,
    verbatimTextOutput("dateText"),
    verbatimTextOutput("dateText2"),
    verbatimTextOutput("dateRangeText"),
    verbatimTextOutput("dateRangeText2")
  )
)
