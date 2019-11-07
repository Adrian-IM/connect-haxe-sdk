package connect.models;

import connect.api.QueryParams;


/**
    Conversation.
**/
class Conversation extends IdModel {
    /**
        The id of object based on which discussion is made, e.g. listing request.
        It can be any object.
    **/
    public var instanceId: String;


    /** Date of the Conversation creation. **/
    public var created: String;


    /** Conversation topic. **/
    public var topic: String;


    /** Collection of messages. **/
    public var messages: Collection<Message>;


    /** Creator of the conversation. **/
    public var creator: User;


    /**
        Lists conversations.

        @returns A collection of Conversations.
    **/
    public static function list(filters: QueryParams) : Collection<Conversation> {
        var convs = Env.getGeneralApi().listConversations(filters);
        return Model.parseArray(Conversation, convs);
    }
    
    
    /**
        Creates a new conversation, linked to the given `instanceId`, and with the
        specified `topic`.

        @returns The created Conversation.
    **/
    public static function create(instanceId: String, topic: String): Conversation {
        var conv = Env.getGeneralApi().createConversation(haxe.Json.stringify({
            instance_id: instanceId,
            topic: topic
        }));
        return Model.parse(Conversation, conv);
    }


    /** @returns The Conversation with the given id, or `null` if it was not found. **/
    public static function get(id: String): Conversation {
        try {
            var conv = Env.getGeneralApi().getConversation(id);
            return Model.parse(Conversation, conv);
        } catch (ex: Dynamic) {
            return null;
        }
    }


    /**
        Creates a new message in `this` Conversation with the given `text`, as long as the text
        is not the same as the one in the last `Message`.

        @returns The created `Message`, or `null` if the last message in the `Conversation` is
        the same as this one.
    **/
    public function createMessage(text: String): Message {
        if (isDifferentToLastMessage(text)) {
            final msg = Env.getGeneralApi().createConversationMessage(
                this.id,
                haxe.Json.stringify({ text: text }));
            final message = Model.parse(Message, msg);
            this.messages.push(message);
            return message;
        } else {
            return null;
        }
    }


    public function new() {
        super();
        this._setFieldClassNames([
            'creator' => 'User'
        ]);
    }


    private function isDifferentToLastMessage(msg: String): Bool {
        final length = this.messages.length();
        if (length > 0 && this.messages.get(length-1).text == msg) {
            return false;
        } else {
            return true;
        }
    }
}
