import azure.functions as func

blueprint = func.Blueprint()


@blueprint.function_name("http-trigger")
@blueprint.route(methods=[func.HttpMethod.POST], auth_level=func.AuthLevel.ANONYMOUS)
def main(request: func.HttpRequest):
    data = request.get_json()
    return data
