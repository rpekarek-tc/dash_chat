part of dash_chat;

class AutoCompleteChatInputToolbar extends StatelessWidget {
  final TextEditingController controller;
  final TextStyle inputTextStyle;
  final InputDecoration inputDecoration;
  final TextCapitalization textCapitalization;
  final BoxDecoration inputContainerStyle;
  final List<Widget> leading;
  final List<Widget> trailing;
  final int inputMaxLines;
  final int maxInputLength;
  final bool alwaysShowSend;
  final ChatUser user;
  final Function(ChatMessage) onSend;
  final String text;
  final Function(String) onTextChange;
  final bool inputDisabled;
  final String Function() messageIdGenerator;
  final Widget Function(Function) sendButtonBuilder;
  final Widget Function() inputFooterBuilder;
  final double inputCursorWidth;
  final Color inputCursorColor;
  final ScrollController scrollController;
  final bool showTraillingBeforeSend;
  final FocusNode focusNode;
  final EdgeInsets inputToolbarPadding;
  final EdgeInsets inputToolbarMargin;
  final TextDirection textDirection;
  final bool sendOnEnter;
  final bool reverse;
  final TextInputAction textInputAction;
  final SuggestionsCallback<ChatUser> getMentionSuggestions;
  final Widget Function(BuildContext, ChatUser) mentionSuggestionBuilder;

  AutoCompleteChatInputToolbar({
    Key key,
    this.textDirection = TextDirection.ltr,
    this.focusNode,
    this.scrollController,
    this.text,
    @required this.getMentionSuggestions,
    @required this.mentionSuggestionBuilder,
    this.textInputAction,
    this.sendOnEnter = false,
    this.onTextChange,
    this.inputDisabled = false,
    this.controller,
    this.leading = const [],
    this.trailing = const [],
    this.inputDecoration,
    this.textCapitalization,
    this.inputTextStyle,
    this.inputContainerStyle,
    this.inputMaxLines = 1,
    this.maxInputLength,
    this.inputCursorWidth = 2.0,
    this.inputCursorColor,
    this.onSend,
    this.reverse = false,
    @required this.user,
    this.alwaysShowSend = false,
    this.messageIdGenerator,
    this.inputFooterBuilder,
    this.sendButtonBuilder,
    this.showTraillingBeforeSend = true,
    this.inputToolbarPadding = const EdgeInsets.all(0.0),
    this.inputToolbarMargin = const EdgeInsets.all(0.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<ChatUser> noSuggestions = [];
    ChatMessage message = ChatMessage(
      text: text,
      user: user,
      messageIdGenerator: messageIdGenerator,
      createdAt: DateTime.now(),
    );

    return Container(
      padding: inputToolbarPadding,
      margin: inputToolbarMargin,
      decoration: inputContainerStyle != null
          ? inputContainerStyle
          : BoxDecoration(color: Colors.transparent),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              ...leading,
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Directionality(
                    textDirection: textDirection,
                    child: TypeAheadField<ChatUser>(
                      direction: AxisDirection.up,
                      hideOnEmpty: true,
                      keepSuggestionsOnSuggestionSelected: true,
                      hideSuggestionsOnKeyboardHide:
                          false, //Attempting fix mentioned here: https://github.com/AbdulRahmanAlHamali/flutter_typeahead/issues/278
                      onSuggestionSelected: (suggestion) {
                        int cursor = controller.value.selection.base.offset;
                        int lastAtSymbol = controller.text
                            .substring(0, cursor)
                            .lastIndexOf('@');
                        if (lastAtSymbol < 0) return;

                        int newCursorPos = lastAtSymbol +
                            suggestion.name.length +
                            2; //account for space at end
                        String newText = controller.text.replaceRange(
                            lastAtSymbol, cursor, '@${suggestion.name} ');
                        TextSelection newSelection = controller.selection
                            .copyWith(
                                baseOffset: newCursorPos,
                                extentOffset: newCursorPos);

                        controller.value = controller.value
                            .copyWith(text: newText, selection: newSelection);

                        onTextChange?.call(newText);
                      },
                      suggestionsCallback: (String pattern) {
                        int cursor = controller.value.selection.base.offset;
                        int lastAtSymbol =
                            (pattern.substring(0, cursor) ?? pattern)
                                .lastIndexOf('@');
                        if (lastAtSymbol < 0) return noSuggestions;
                        if (lastAtSymbol != 0) {
                          int lastSpace =
                              (pattern.substring(lastAtSymbol, cursor) ??
                                      pattern)
                                  .lastIndexOf(' ');
                          if (lastSpace > 0) return noSuggestions;
                        }
                        return getMentionSuggestions?.call(
                                pattern.substring(lastAtSymbol, cursor)) ??
                            noSuggestions;
                      },
                      itemBuilder: mentionSuggestionBuilder,
                      textFieldConfiguration: TextFieldConfiguration(
                        focusNode: focusNode,
                        onChanged: (value) {
                          onTextChange(value);
                        },
                        onSubmitted: (value) {
                          if (sendOnEnter) {
                            _sendMessage(context, message);
                          }
                        },
                        keyboardType: TextInputType.multiline,
                        textInputAction: textInputAction,
                        decoration: inputDecoration != null
                            ? inputDecoration
                            : InputDecoration.collapsed(
                                hintText: "",
                                fillColor: Colors.white,
                              ),
                        textCapitalization: textCapitalization,
                        controller: controller,
                        style: inputTextStyle,
                        maxLength: maxInputLength,
                        minLines: 1,
                        maxLines: inputMaxLines,
                        cursorColor: inputCursorColor,
                        cursorWidth: inputCursorWidth,
                        enabled: !inputDisabled,
                      ),
                    ),
                  ),
                ),
              ),
              if (showTraillingBeforeSend) ...trailing,
              if (sendButtonBuilder != null)
                sendButtonBuilder(() async {
                  if (text.length != 0) {
                    await onSend(message);

                    controller.text = "";

                    onTextChange("");
                  }
                })
              else
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: alwaysShowSend || text.length != 0
                      ? () => _sendMessage(context, message)
                      : null,
                ),
              if (!showTraillingBeforeSend) ...trailing,
            ],
          ),
          if (inputFooterBuilder != null) inputFooterBuilder()
        ],
      ),
    );
  }

  void _sendMessage(BuildContext context, ChatMessage message) async {
    if (text.length != 0) {
      await onSend(message);

      controller.text = "";

      onTextChange("");

      FocusScope.of(context).requestFocus(focusNode);

      Timer(Duration(milliseconds: 150), () {
        scrollController.animateTo(
          reverse ? 0.0 : scrollController.position.maxScrollExtent + 30.0,
          curve: Curves.easeOut,
          duration: const Duration(milliseconds: 300),
        );
      });
    }
  }
}
