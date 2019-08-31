class FavoritesStoreException(Exception):

    '''
    Raised when unable to retrieve data from a favorites store
    '''

    pass

class FavoritesStoreUserNotFoundException(Exception):

    '''
    Raised when the requested user is not found in a favorites store
    '''

    pass