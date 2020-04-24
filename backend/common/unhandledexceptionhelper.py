import sys
import logging
import threading

class UnhandledExceptionHelper:
    '''
    Adds support for catching unhandled exceptions and incrementing a metric that we can then alert on.

    Based on https://www.customprogrammingsolutions.com/tutorial/2018-02-06/python-excepthook-logging/
    '''

    _metrics_helper = None

    @staticmethod
    def setup_unhandled_exception_handler(metrics_helper):
        
        UnhandledExceptionHelper._metrics_helper = metrics_helper

        sys.excepthook = UnhandledExceptionHelper._handle_unhandled_exception
        threading.excepthook = UnhandledExceptionHelper._handle_unhandled_threading_exception

    @staticmethod
    def _handle_unhandled_threading_exception(args):

        thread_identifier = 0

        if args.thread is not None:
            thread_identifier = args.thread.get_ident()

        UnhandledExceptionHelper._handle_unhandled_exception(args.exc_type, args.exc_value, args.exc_traceback, thread_identifier)

    @staticmethod
    def _handle_unhandled_exception(exc_type, exc_value, exc_traceback, thread_identifier=0):

        if issubclass(exc_type, KeyboardInterrupt):
            # call the default excepthook saved at __excepthook__
            sys.__excepthook__(exc_type, exc_value, exc_traceback)
            return
        
        logging.error(f"Unhandled exception. Thread ID: {thread_identifier if (thread_identifier != 0) else 'Main thread'}", exc_info=(exc_type, exc_value, exc_traceback))

        UnhandledExceptionHelper._metrics_helper.increment_count("UnhandledException")