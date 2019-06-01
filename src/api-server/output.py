class Output:

    @staticmethod
    def get_output(photo_recommendations):

        output = ""

        output += "<h1>Photos you may like</h1>\n"

        for photo in photo_recommendations:
            output += f"<a href=https://www.flickr.com/photos/{photo['image_owner']}/{photo['photo_id']}/><img src={photo['image_url']}/></a><br/>\n"

        return output