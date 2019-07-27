import sys
import logging
import threading

class UnhandledExceptionHelper:
    '''
    Adds support for catching unhandled exceptions and incrementing a metric that we can then alert on.

    Based on https://www.customprogrammingsolutions.com/tutorial/2018-02-06/python-excepthook-logging/

    Note that when Python 3.8 is released we can simplify the threading part of this: 
        - https://bugs.python.org/issue1230540
        - https://docs.python.org/3.8/whatsnew/3.8.html
    '''

    _metrics_helper = None

    @staticmethod
    def setup_unhandled_exception_handler(metrics_helper):
        
        UnhandledExceptionHelper._metrics_helper = metrics_helper

        sys.excepthook = UnhandledExceptionHelper._handle_unhandled_exception

        UnhandledExceptionHelper._patch_threading_excepthook() # This can be replaced after Python 3.8 is out

    @staticmethod
    def _patch_threading_excepthook():

        # Installs our exception handler into the threading modules Thread object
        # Inspired by https://bugs.python.org/issue1230540
        
        old_init = threading.Thread.__init__
        
        def new_init(self, *args, **kwargs):
            old_init(self, *args, **kwargs)
            old_run = self.run
            def run_with_our_excepthook(*args, **kwargs):
                try:
                    old_run(*args, **kwargs)
                except (KeyboardInterrupt, SystemExit):
                    raise
                except:
                    sys.excepthook(*sys.exc_info(), thread_identifier=threading.get_ident())
            self.run = run_with_our_excepthook
        
        threading.Thread.__init__ = new_init

    @staticmethod
    def _handle_unhandled_exception(exc_type, exc_value, exc_traceback, thread_identifier=0):

        if issubclass(exc_type, KeyboardInterrupt):
            # call the default excepthook saved at __excepthook__
            sys.__excepthook__(exc_type, exc_value, exc_traceback)
            return
        
        logging.error(f"Unhandled exception. Thread ID: {thread_identifier if (thread_identifier != 0) else 'Main thread'}", exc_info=(exc_type, exc_value, exc_traceback))

        UnhandledExceptionHelper._metrics_helper.increment_count("UnhandledException")