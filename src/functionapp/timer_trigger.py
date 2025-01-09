import datetime
import logging

import azure.functions as func


blueprint = func.Blueprint()


@blueprint.function_name("timer-trigger")
@blueprint.timer_trigger(arg_name="timer", schedule="0 */5 * * * *")
def main(timer: func.TimerRequest) -> None:
    now = datetime.datetime.now(datetime.timezone.utc).isoformat()

    logging.info(f'Timer trigger function ran at {now}')
