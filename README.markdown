Asbestos
========

Template handler for Rails that allows you to use
a subset of XML Builder markup to produce JSON.

Take, for instance, a common "show.xml.builder" template:

    xml.instruct!
    xml.category(:private => false) do
      xml.name @category.name
      xml.parent do
        xml.id @category.parent_id
        xml.name @category.parent.name
      end
    end

If you copied that to "show.json.asbestos", you would get:
    
    {"category": {
      "private": "false",
      "name": "Science & Technology",
      "parent": {
        "id": 1,
        "name": "Religion"
      }
    }}

But of course, you don't want to duplicate your builder template
in another file, so we'll handle this in the controller:

    def show
      respond_to do |wants|
        wants.xml
        wants.json {
          # takes the "show.xml.builder" template and renders it to JSON
          render_json_from_xml
        }
      end
    end

With this method there's no need for a special template file for JSON.
Asbestos is designed to use existing XML Builder templates.

How does it work?
-----------------

The `xml` variable in your normal builder templates is the XML Builder object.
When you call methods on this object, it turns that into XML nodes and appends
everything to a string, which is later returned as the result of rendering.

This plugin provides Asbestos::Builder, which tries to mimic the behavior
of the XML Builder while saving all the data to a big nested ruby hash.
In the end, `to_json` is called on it.

Aggregates and ignores (important!)
-----------------------------------

Problems start when you have Builder templates that render *collections*,
like in index actions:

    xml.instruct!
    for category in @categories
      xml.category do
        # ...
      end
    end

There is a ruby loop in there, so if there are multiple categories the resulting
JSON would have just one. This is because the same "category" field in the JSON
hash would keep getting re-written by the next iteration. Asbestos::Builder is,
unfortunately, not aware about any loops in your template code.

The solution is to indicate explicitly which keys you want aggregated:

    render_json_from_xml :aggregate => ['category']

Now, what would previously create a "category" key will get aggregated
under a "categories" array, instead:

    { "categories": [ ... ] }

Sometimes, most often with root elements, you want a key ignored.
You can specify which occurrences to ignore:

    render_json_from_xml :ignore => ['category']
