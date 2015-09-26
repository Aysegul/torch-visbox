-- global ui object
-- holds ui state and defines listeners and functions for manipulating it
local ui = {}

-- connect all buttons to actions
ui.classes = {widget.pushButton_1, widget.pushButton_2, widget.pushButton_3, widget.pushButton_4, widget.pushButton_5}
ui.currentId = 1
state.request = {x=0, y=0}

-- set current class to learn
for i,button in ipairs(ui.classes) do
   button.text = state.classes[i]
   qt.connect(qt.QtLuaListener(button),
              'sigMousePress(int,int,QByteArray,QByteArray,QByteArray)',
              function (...)
                 ui.currentId = i
                 ui.currentClass = state.classes[i]
                 state.request = {}
              end)
end

-- connect mouse pos
widget.frame.mouseTracking = true
qt.connect(qt.QtLuaListener(widget.frame),
           'sigMouseMove(int,int,QByteArray,QByteArray)',
           function (x,y)
              ui.mouse = {x=x,y=y}
           end)

-- issue learning request
qt.connect(qt.QtLuaListener(widget),
           'sigMousePress(int,int,QByteArray,QByteArray,QByteArray)',
           function (...)
              if ui.mouse then
                 state.request = {}
                 local no_features = state.network.modules[state.network_table[ui.currentId].i].output:size(1)
                 local x_features = state.network.modules[state.network_table[ui.currentId].i].output:size(2)
                 local y_features = state.network.modules[state.network_table[ui.currentId].i].output:size(3)

                 local rows = math.floor(math.sqrt(no_features))
                 local cols = math.ceil(no_features/rows)
                 --calculate which feature map
                 local x_row = math.floor((ui.mouse.x - options.eye * window_zoom - 20)/((x_features+1)*options.zoom_f))
                 local y_col = math.floor((ui.mouse.y-30)/((y_features+1)*options.zoom_f))
                 state.request = {x=x_row, y=y_col}

              end
           end)

ui.resize = true

widget.windowTitle = title
widget:show()



-- return ui
return ui
