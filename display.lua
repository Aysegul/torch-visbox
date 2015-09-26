local display = {}
local source = image.Camera{}
-- function to update display
function display.update()
   if ui.resize then
      widget.geometry = qt.QRect{x=100,y=100,width=1080,height=1080}
      ui.resize = false
   end

   painter:gbegin()
   painter:showpage()

   options.zoom =  widget.doubleSpinBox_2.value
   options.zoom_f = widget.doubleSpinBox_1.value
   window_zoom = 1

   -- capture next frame
   state.rawFrame = source:forward()

   -- crop square
   local size = math.min(state.rawFrame:size(2), state.rawFrame:size(3))
   local t = math.floor((state.rawFrame:size(2) - size)/2 + 1)
   local l = math.floor((state.rawFrame:size(3) - size)/2 + 1)
   local b = t + size - 1
   local r = l + size - 1
   state.rawFrame= state.rawFrame[{ {},{t,b},{l,r} }]

   state.rawFrame = image.scale(state.rawFrame,options.eye, options.eye)
   state.rawFrame:add(-options.mean):div(options.std)

   local output = state.network:forward(state.rawFrame)
   local prob, idx = torch.max(output, 1)

   -- image to display
   local dispimg = state.rawFrame

   -- display input image
   image.display{image=dispimg,
                 win=painter,
                 zoom=window_zoom}

   painter:setcolor('black')
   painter:setfont(qt.QFont{serif=false,italic=false,size=14})
   painter:moveto(0, options.eye * window_zoom +20)
   painter:show('Prediction: '.. state.label[idx:squeeze()])
   painter:moveto(0, options.eye * window_zoom +40)
   painter:show('Probability:' .. prob:squeeze())

   painter:moveto(options.eye * window_zoom +20, 20)
   painter:show('Visualization of: '..state.network_table[ui.currentId].name)


   local no_features = state.network.modules[state.network_table[ui.currentId].i].output:size(1)
   local x_features = state.network.modules[state.network_table[ui.currentId].i].output:size(2)
   local y_features = state.network.modules[state.network_table[ui.currentId].i].output:size(3)

   local rows = math.floor(math.sqrt(no_features))
   local cols = math.ceil(no_features/rows)

   image.display{image=state.network.modules[state.network_table[ui.currentId].i].output,
                win=painter,
                x= options.eye * window_zoom +20,
                y=30,
                padding = 1,
                nrow = rows,
                zoom = options.zoom_f}


   -- draw a box around request
   if state.request and state.request.x then
      local x = state.request.x
      local y = state.request.y
      painter:setcolor('red')
      painter:setlinewidth(3)

      if (x>=0 and x<rows) and (y>=0 and y<cols) and ((x+1)+(y)*rows <= no_features)then
          painter:rectangle(x*(x_features+1)*options.zoom_f + options.eye*window_zoom +20, y*(y_features+1)*options.zoom_f+30, x_features*options.zoom_f, y_features*options.zoom_f)
          painter:stroke()
          painter:setfont(qt.QFont{serif=false,italic=false,size=14})

          local feature_map = state.network.modules[state.network_table[ui.currentId].i].output[(x+1)+(y)*rows]:clone()
          state.network.modules[state.network_table[ui.currentId].i].output:fill(0)
          state.network.modules[state.network_table[ui.currentId].i].output[(x+1)+(y)*rows]:copy(feature_map)

          local deconvnet = nn.Sequential()
          for i=1, state.network_table[ui.currentId].i do
             deconvnet:add(state.network.modules[i])
          end
          deconvnet:backward(state.rawFrame, state.network.modules[state.network_table[ui.currentId].i].output)
          image.display{image=deconvnet.modules[1].gradInput,
                        win=painter,
                        x= 0,
                        y=options.eye * window_zoom + 60,
                        zoom = window_zoom}
          image.display{image=feature_map,
                        win=painter,
                        x= 0,
                        y=2*options.eye * window_zoom + 90,
                        zoom = options.zoom}
      end   
   end
   painter:gend()
end


-- display loop
local timer = qt.QTimer()
timer.interval = 10
timer.singleShot = true
function display.begin()
   local function finishloop()
        display.update()
        collectgarbage()
        timer:start()
   end
   qt.connect(timer,
              'timeout()',
              finishloop)
   timer:start()      
end


return display
