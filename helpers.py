def confirmation(msg,prompt):
    while True:
        reply = input(f"{msg} - {prompt}")
        reply = reply.strip().lower()
        if len(reply) == 1:
            if reply == 'y':
                return True
            if reply == 'n' or reply == 'q':
                return False
