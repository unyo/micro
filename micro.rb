require "uri"
require "find"

require "sinatra"
require "haml"
require "sass"
require "coffee-script"
require "sinatra/reloader"
require "sinatra/json"

set :bind, "0.0.0.0"

get "/" do
    @intro = "
    "
    haml :index
end

get "/style.css" do
    sass :style
end

get "/editor.js" do
    coffee :editor
end

get "/ls/" do
    data = {
        ls: Dir[File.join('.', '**', '*')]
    }
    json data
end

get "/ls/:search" do
    search = params[:search] ? '*'+URI.decode(params[:search])+'*' : '*'
    halt 403 if search.include? ".."
    data = {
        ls: Dir[File.join('.', '**', search)]
    }
    json data
end

get %r{/edit/(.*)} do |filename|
    @filename = filename
    haml :edit
end

get "/file/intro" do
    erb :intro, :layout => false
end

get %r{/file/(.*)} do |filename|
    halt 403 if filename.include? ".."
    halt 404 unless File.file?(filename)
    stream do |out|
        File.foreach(filename) do |line|
            out << line
        end
    end
end

post "/file/:filename" do
    File.write(params[:filename], request.body.read)
end

__END__

@@index
%textarea.edit-area{data: {filename: "intro"}}

@@edit
.search-container
    %input.search
    .search-results
%textarea.edit-area{data: {filename: "#{@filename}"}}

@@layout
!!! 5
%html
    %head
        %title
            In-browser Editor
        %link{rel: "stylesheet", href: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/codemirror.css"}
        %link{rel: "stylesheet", href: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/theme/zenburn.css"}
        %link{rel: "stylesheet", href: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/addon/fold/foldgutter.css"}
        %link{rel: "stylesheet", href: "/style.css"}
    %body
        = yield
    %script{src: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/codemirror.js"}
    %script{src: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/mode/xml/xml.js"}
    %script{src: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/mode/css/css.js"}
    %script{src: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/mode/javascript/javascript.js"}
    %script{src: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/mode/ruby/ruby.js"}
    %script{src: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/mode/python/python.js"}
    %script{src: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/mode/htmlmixed/htmlmixed.js"}
    %script{src: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/mode/sass/sass.js"}
    %script{src: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/mode/coffeescript/coffeescript.js"}
    %script{src: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/mode/haml/haml.js"}
    %script{src: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/addon/runmode/colorize.js"}
    %script{src: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/addon/fold/foldcode.js"}
    %script{src: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/addon/fold/foldgutter.js"}
    %script{src: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/addon/fold/indent-fold.js"}
    %script{src: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/addon/fold/xml-fold.js"}
    %script{src: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/addon/fold/brace-fold.js"}
    %script{src: "https://cdnjs.cloudflare.com/ajax/libs/codemirror/4.12.0/addon/fold/comment-fold.js"}
    %script{src: "https://code.jquery.com/jquery-2.1.3.js"}
    %script{src: "/editor.js"}

@@style
body
    margin: 0
.edit-area, .CodeMirror
    width: 100vw
    height: 100vh
    box-sizing: border-box
.search-container
    position: fixed
    right: 0
    top: 0
    z-index: 100
    background-color: white
    opacity: 0.75
    .edit-link
        display: block
        font-family: monospace
        color: black
        text-decoration: none
        &:hover
            background-color: black
            color: white

@@editor
console.debug "starting editor"
edit_area = $('.edit-area')[0]
# setup the default options
options = 
    theme: "zenburn"
    mode: "htmlmixed"
    autofocus: true
    indentUnit: 4
    lineNumbers: true
    foldGutter: true
    gutters: ["CodeMirror-foldgutter", "CodeMirror-linenumbers"]
# check if we should be displaying a file
filename = $(edit_area).data 'filename'
# if we are
if filename
    # detect the file type and setup syntax highlighting accordingly
    if filename.indexOf('.rb') > 0
        options.mode = "ruby"
    if filename.indexOf('.python') > 0
        options.mode = "python"
    if filename.indexOf('.html') > 0
        options.mode = "htmlmixed"
    if filename.indexOf('.js') > 0
        options.mode = "javascript"
    if filename.indexOf('.css') > 0
        options.mode = 'css'
    if filename.indexOf('.sass') > 0
        option.mode = 'sass'
    if filename.indexOf('haml') > 0
        option.mode = 'haml'
    if filename.indexOf('xml') > 0
        option.mode = 'xml'
    # read in the file
    read_path = '/file/'+filename
    $.get read_path, (result) ->
        # and set up the editor
        $(edit_area).text(result)
        window.editor = CodeMirror.fromTextArea edit_area, options
# otherwise, just load the thing
else
    window.editor = CodeMirror.fromTextArea edit_area, options

console.debug("setting up search")
# next, setup search
$('.search').on 'keydown', (e) ->
    target = $(e.currentTarget);
    search_term = target.val()
    encoded_search_term = encodeURIComponent(search_term)
    search_url = '/ls/'+encoded_search_term
    $.get(search_url).then (result) ->
        result_links = result.ls.map (filepath) ->
            filepath_without_dotslash = filepath.replace /^\.[\\\/]/, ''
            result_link = $('<a />', {
                class: "edit-link",
                href: "/edit/"+filepath_without_dotslash
            }).text filepath_without_dotslash
            return result_link
        $('.search-results').html(result_links);

saveFile = (filename) ->
    if !filename
        filename = window.location.pathname.match(/\/edit\/(.*)$/)[1]
    file_contents = window.editor.getValue()
    save_url = '/file/'+filename
    $.post(save_url, file_contents).then (event) ->
        alert('file saved')

# then, setup save
$(window).bind 'keydown', (event) ->
  if event.ctrlKey or event.metaKey
    switch String.fromCharCode(event.which).toLowerCase()
      when 's'
        event.preventDefault()
        alert 'ctrl-s'
        saveFile()
      when 'f'
        event.preventDefault()
        alert 'ctrl-f'
      when 'g'
        event.preventDefault()
        alert 'ctrl-g'

@@intro
In-Browser Editor v0.1 - a single file in-browser IDE

Usage: ruby micro.rb
Description:
    A in-browser editor that you can use to edit 
    source code files on the fly. Simply download
    the ruby file and run within a directory you
    want to serve. Great for Chromebook web devs.
Todo:
    - Saving
    - Pressing 'CTRL' brings up image with hotkeys
    - Pressing 'CTRL-m' or something lets you 
      remap hotkeys
    - Add vi mode hotkey 
    - Clear results on search blur
