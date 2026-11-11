def confirmation(msg,prompt):
    print(msg)
    while True:
        reply = input(prompt)
        reply = reply.strip().lower()
        if len(reply) == 1:
            if reply == 'y':
                return True
            if reply == 'n' or reply == 'q':
                return False
