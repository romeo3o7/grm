def confirmation(msg,prompt):
    print(msg)
    while True:
        reply = input(prompt )
        if len(reply) == 1:
            reply = reply.strip().lower()
            if reply == 'y':
                return True
            if reply == 'n' or reply == 'q':
                return False
