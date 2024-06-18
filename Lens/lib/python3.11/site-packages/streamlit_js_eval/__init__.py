import streamlit.components.v1 as components
import json, os

absolute_path = os.path.dirname(os.path.abspath(__file__))
frontend_path = absolute_path

streamlit_js_eval = components.declare_component(
    "streamlit_js_eval",
    path=frontend_path
)

def set_cookie(name, value, duration_days, component_key=None):
    js_ex = f'setCookie(\'{name}\', \'{value}\', {duration_days})'
    if component_key is None: component_key=js_ex
    return streamlit_js_eval(js_expressions=js_ex, key = component_key )

def get_cookie(name, component_key=None):
    if component_key is None: component_key=f'getCookie_{name}'
    return streamlit_js_eval(js_expressions=f'getCookie(\'{name}\')', key = component_key)

def get_user_agent(component_key=None):
    if component_key is None: component_key='UA'
    return streamlit_js_eval(js_expressions=f'window.navigator.userAgent', key = component_key)

def copy_to_clipboard(copiedText, linkText, successText, component_key=None):
    js_text = ''' 
    setFrameHeight(100);
    document.getElementsByTagName("body")[0].innerHTML += `<a href="#%s" id="cbc" rel="noopener noreferrer">%s</a>`;
    
    document.getElementById("cbc").addEventListener("click", function() {
        console.log('Copying')
        const copiedText = `%s`
        copyToClipboard(copiedText, () => document.getElementById("cbc").innerHTML = '%s' );
        
      })
    '''%(str(87264), linkText, copiedText, successText)
    if component_key is None: component_key=f'{linkText}{copiedText}{successText}'
    return streamlit_js_eval(js_expressions=js_text, key = component_key)

def bootstrapButton(title,component_key=None):
    return streamlit_js_eval(js_expressions=f"bsButton('{title}')", key=component_key if component_key is not None else title)

def get_geolocation(component_key=None):
    js_text = 'getLocation()' 
    if component_key is None: component_key=js_text
    return streamlit_js_eval(js_expressions=js_text, key = component_key)

def get_browser_language(component_key=None):
    if component_key is None: component_key='LANG'
    return streamlit_js_eval(js_expressions=f'window.navigator.language', key = component_key)

def get_page_location(component_key=None):
    if component_key is None: component_key='LOC'
    location_str = streamlit_js_eval(js_expressions='JSON.stringify(window.location)', key = component_key)
    if location_str is not None:
        return json.loads(location_str)
    return None


def create_share_link(sharedObject, linkText, successText, component_key=None):
    js_text = ''' 
    setFrameHeight(100);
    document.getElementsByTagName("body")[0].innerHTML += `<a href="#%s" id="shli">%s</a>`;
    
    document.getElementById("shli").addEventListener("click", function() {
        console.log('Sharing')
        if (navigator.share) {
            navigator.share(%s).then(() => {
            document.getElementById("shli").innerHTML = '%s'
            console.log('Thanks for sharing!');
        })
        .catch(console.error);
        } else {
           console.log('Sharing failed')
        }
      })
    '''%(str(87264), linkText, sharedObject, successText)
    
    if component_key is None: component_key=f'{linkText}{sharedObject}{successText}'

    return streamlit_js_eval(js_expressions=js_text, key = component_key)
