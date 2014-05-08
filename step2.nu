#!/usr/local/bin/nush
;;
;; step2.nu - agent configuration script
;;
;; run this to remotely configure a new agent.
;; agent.crt and agent.key files (for ssl) must be in the current directory
;;

(set args ((NSProcessInfo processInfo) arguments))
(unless (eq (args count) 5)
        (puts "Usage: step2.nu <agent> <username> <password>")
        (exit))

; remote commands to set up an agent
(set agent (args 2))
(set admin-username (args 3))
(set admin-password (args 4))

;; create an admin user
(system "ssh root@#{agent} /home/control/bin/mkadmin #{admin-username} #{admin-password}")

;; install ssl certificates - remote names must be as shown
(system "scp agent.crt root@#{agent}:/home/control/etc/agent.crt")
(system "scp agent.key root@#{agent}:/home/control/etc/agent.key")

;; update nginx configuration
(system "ssh root@#{agent} /usr/sbin/nginx -s stop")
(system "ssh root@#{agent} /home/control/bin/prime-nginx")
