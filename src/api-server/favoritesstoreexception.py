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

class FavoritesStoreDuplicateUserException(Exception):

    '''
    Raised when trying to insert a user into the store that already exists
    '''

    pass