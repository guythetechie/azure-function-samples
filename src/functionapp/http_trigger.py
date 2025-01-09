import azure.functions as func

blueprint = func.Blueprint()


@blueprint.function_name("http-trigger")
@blueprint.route(methods=[func.HttpMethod.POST], auth_level=func.AuthLevel.ANONYMOUS)
def main(req: func.HttpRequest):
    data = req.get_json()
    return func.HttpResponse(data, status_code=200)
