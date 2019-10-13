#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <string.h>
#include <unistd.h>
#include <netdb.h>
#define tellosocket_buff_len 8192

//return socket fd
int tellosocket_server(const char *address, int port) {
    
    //create socket
    int socketfd = 0, broadcast = 1, r = -1;
    socketfd = socket(AF_INET, SOCK_DGRAM, 0);
    
    //bind
    struct sockaddr_in serv_addr;
    memset( &serv_addr, 0, sizeof(serv_addr));
    serv_addr.sin_len = sizeof(struct sockaddr_in);
    serv_addr.sin_family = AF_INET;
    
    r = setsockopt(socketfd, SOL_SOCKET, SO_BROADCAST, &broadcast, sizeof(broadcast));
    serv_addr.sin_port = htons(port);
    serv_addr.sin_addr.s_addr = htonl(INADDR_ANY);
    
    if (r == -1){
        return -1;
    }
    
    r = bind(socketfd, (struct sockaddr *) &serv_addr, sizeof(serv_addr));

    if (r == 0) {
        return socketfd;
    } else {
        return -1;
    }
    
}

int yudpsocket_recive(int socket_fd, char *outdata, int expted_len, char *remoteip, int *remoteport) {
    struct sockaddr_in cli_addr;
    socklen_t clilen = sizeof(cli_addr);
    memset(&cli_addr, 0x0, sizeof(struct sockaddr_in));
    int len = (int)recvfrom(socket_fd, outdata, expted_len, 0, (struct sockaddr *)&cli_addr, &clilen);
    char *clientip = inet_ntoa(cli_addr.sin_addr);
    memcpy(remoteip, clientip, strlen(clientip));
    *remoteport = cli_addr.sin_port;
  
    return len;
}

int tellosocket_close(int socketfd) {
    return close(socketfd);
}

//return socket fd
int yudpsocket_client() {
    //create socket
    int socketfd = socket(AF_INET, SOCK_DGRAM, 0);
    int reuseon = 1;
    setsockopt(socketfd, SOL_SOCKET, SO_REUSEADDR, &reuseon, sizeof(reuseon));
  
    return socketfd;
}

int yudpsocket_get_server_ip(char *host, char *ip) {
    struct hostent *hp;
    struct sockaddr_in address;
  
    hp = gethostbyname(host);
    if (hp == NULL) {
        return -1;
    }
  
    bcopy((char *)hp->h_addr, (char *)&address.sin_addr, hp->h_length);
    char *clientip = inet_ntoa(address.sin_addr);
    memcpy(ip, clientip, strlen(clientip));
  
    return 0;
}

int tellosocket_sendto(int socketfd, char *msg, int len, char *toaddr, int toport) {
    
    struct sockaddr_in address;
    socklen_t addrlen = sizeof(address);
    memset(&address, 0x0, sizeof(struct sockaddr_in));
    
    address.sin_family = AF_INET;
    address.sin_port = htons(toport);
    address.sin_addr.s_addr = inet_addr(toaddr);
    int sendlen = (int)sendto(socketfd, msg, len, 0, (struct sockaddr *)&address, addrlen);
  
    return sendlen;
}
