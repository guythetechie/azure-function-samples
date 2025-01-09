import azure.functions as func
from http_trigger import blueprint as http_trigger_blueprint
from timer_trigger import blueprint as timer_trigger_blueprint

app = func.FunctionApp()

app.register_functions(http_trigger_blueprint)
app.register_functions(timer_trigger_blueprint)
