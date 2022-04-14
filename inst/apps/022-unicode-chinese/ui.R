# 定义用户界面
fluidPage(

  # 标题
  titlePanel("麻麻再也不用担心我的Shiny应用不能显示中文了"),

  # 侧边栏布局
  sidebarLayout(
    sidebarPanel(
      selectInput("dataset", "请选一个数据：",
                  choices = c("岩石", "pressure", "cars")),

      uiOutput("rockvars"),

      numericInput("obs", "查看多少行数据？", 5),

      checkboxInput("summary", "显示概要", TRUE)
    ),

    # 展示一个HTML表格
    mainPanel(
      conditionalPanel("input.dataset === '岩石'", plotOutput("rockplot")),

      verbatimTextOutput("summary这里也可以用中文"),

      tableOutput("view")
    )
  ),
  shinyjster::shinyjster_js("
  // used `Jster.unicode.escape(x, true)` to generate unicode characters.

  var jst = jster();
  jst.add(Jster.shiny.waitUntilStable);
  jst.add(function() {
    // title
    Jster.assert.isEqual(
      $('h2').first().html(),
      '\\u9ebb\\u9ebb\\u518d\\u4e5f\\u4e0d\\u7528\\u62c5\\u5fc3\\u6211\\u7684Shiny\\u5e94\\u7528\\u4e0d\\u80fd\\u663e\\u793a\\u4e2d\\u6587\\u4e86'
    );

    // first dropdown
    Jster.assert.isEqual(
      Jster.selectize.label('dataset'),
      '\\u8bf7\\u9009\\u4e00\\u4e2a\\u6570\\u636e\\uff1a'
    );
    Jster.assert.isEqual(
      Jster.selectize.currentOption('dataset'),
      '\\u5ca9\\u77f3'
    );

    // second dropdown
    Jster.assert.isEqual(
      Jster.selectize.label('vars'),
      '\\u4ece\\u5ca9\\u77f3\\u6570\\u636e\\u4e2d\\u9009\\u62e9\\u4e00\\u5217\\u4f5c\\u4e3a\\u81ea\\u53d8\\u91cf'
    );
    Jster.assert.isEqual(
      Jster.selectize.currentOption('vars'),
      '\\u5468\\u957f'
    );

    // third dropdown
    Jster.assert.isEqual(
      Jster.input.label('obs'),
      '\\u67e5\\u770b\\u591a\\u5c11\\u884c\\u6570\\u636e\\uff1f'
    );
    Jster.assert.isEqual(
      Jster.input.currentOption('obs'),
      '5'
    );

    // checkbox
    Jster.assert.isEqual(
      Jster.checkbox.label('summary'),
      '\\u663e\\u793a\\u6982\\u8981'
    );

    // table headers
    var tableHeaderValues = ['\\u9762\\u79ef', '\\u5468\\u957f', '\\u5f62\\u72b6', '\\u6e17\\u900f\\u6027'];
    $('#view th').map(function(idx, val) {
      var tableHeader = $(val).text().trim();
      Jster.assert.isEqual(
        tableHeader,
        tableHeaderValues[idx]
      );
    });

    // unicode id
    var summaryHeaderText = $('#summary\\u8fd9\\u91cc\\u4e5f\\u53ef\\u4ee5\\u7528\\u4e2d\\u6587').text().split('\\n')[0];
    $.trim(summaryHeaderText).split(/ +/g).map(function(val, idx) {
      Jster.assert.isEqual(
        val,
        tableHeaderValues[idx]
      );
    });

  });

  jst.test();
  ")
)
