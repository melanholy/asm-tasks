#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <sys/poll.h>

#define PORT 31000

struct my_string
{
    char *s;
    int c;
};

struct my_string string_create(char *s)
{
    struct my_string res;
    res.s = strdup(s);
    res.c = strlen(s);

    return res;
}

struct my_string string_copy(struct my_string s)
{
    struct my_string copy;
    copy.s = strdup(s.s);
    copy.c = s.c;

    return copy;
}

struct k_v
{
    struct my_string k;
    struct my_string v;
};

struct my_list
{
    struct k_v *_array;
    int capacity;
    int count;
};

struct my_list list_create()
{
    const int initial_capacity = 32;

    struct k_v *array = (struct k_v *)malloc(initial_capacity * sizeof(struct k_v));
    struct my_list list = {array, initial_capacity, 0};

    return list;
}

void list_add(struct my_list *list, struct k_v elem)
{
    if (list->count == list->capacity)
    {
        list->_array = (struct k_v *)realloc(list->_array, list->capacity * 2 * sizeof(struct k_v));
        list->capacity *= 2;
    }

    struct k_v elem_copy = {string_copy(elem.k), string_copy(elem.v)};
    memcpy(&list->_array[list->count], &elem_copy, sizeof(struct k_v));
    list->count++;
}

struct k_v list_get(struct my_list *list, int index)
{
    return list->_array[index];
}

void list_update(struct my_list *list, int index, struct my_string value)
{
    struct my_string value_copy = string_copy(value);
    free(list->_array[index].v.s);
    memcpy(&list->_array[index].v, &value_copy, sizeof(value_copy));
}

int list_find(struct my_list *list, char *key)
{
    for (int i = 0; i < list->count; i++)
    {
        if (!strcmp(list_get(list, i).k.s, key))
            return i;
    }

    return -1;
}

void list_remove(struct my_list *list, int index)
{
    memmove(&list->_array[index], &list->_array[index+1], (list->count - index) * sizeof(struct k_v));
    list->count--;
}

struct my_string *list_all_handler(struct my_list *list, char **argv, int *resc)
{
    *resc = list->count;
    struct my_string *res = (struct my_string *)malloc(sizeof(struct my_string) * list->count);

    for (int i = 0; i < list->count; i++)
    {
        struct my_string key = string_copy(list_get(list, i).k);
        memcpy(&res[i], &key, sizeof(key));
    }

    return res;
}

struct my_string *add_handler(struct my_list *list, char **argv, int *resc)
{
    *resc = 0;
    struct my_string *res = (struct my_string *)malloc(sizeof(struct my_string) * 0);

    int existing_index = list_find(list, argv[0]);
    if (existing_index != -1)
    {
        struct my_string value = string_create(argv[1]);
        list_update(list, existing_index, value);

        free(value.s);
    }
    else
    {
        struct my_string key = string_create(argv[0]);
        struct my_string value = string_create(argv[1]);
        list_add(list, (struct k_v){key, value});

        free(key.s);
        free(value.s);
    }

    return res;
}

struct my_string *get_handler(struct my_list *list, char **argv, int *resc)
{
    struct my_string *res;
    int index = list_find(list, argv[0]);
    if (index != -1)
    {
        *resc = 1;
        res = (struct my_string *)malloc(sizeof(struct my_string) * 1);
        struct my_string value = string_copy(list_get(list, index).v);
        memcpy(&res[0], &value, sizeof(value));
    }
    else
    {
        *resc = 0;
        res = (struct my_string *)malloc(sizeof(struct my_string) * 0);
    }

    return res;
}

struct my_string *remove_handler(struct my_list *list, char **argv, int *resc)
{
    *resc = 0;
    struct my_string *res = (struct my_string *)malloc(sizeof(struct my_string) * 0);

    int index = list_find(list, argv[0]);
    if (index != -1)
        list_remove(list, index);

    return res;
}

struct my_string *count_handler(struct my_list *list, char **argv, int *resc)
{
    *resc = 1;
    struct my_string *res = (struct my_string *)malloc(sizeof(struct my_string) * 1);

    char count_arr[1024];
    sprintf(count_arr, "%d", list->count);
    struct my_string count_str = string_create(count_arr);
    memcpy(&res[0], &count_str, sizeof(count_str));

    return res;
}

int sendall(int socket, char *buffer, int length)
{
    while (length)
    {
        int sent = send(socket, buffer, length, 0);
        if (sent < 0)
            return sent;

        buffer += sent;
        length -= sent;
    }

    return 0;
}

int recvall(int socket, char *buffer, int length)
{
    while (length)
    {
        int received = recv(socket, buffer, length, 0);
        if (received < 0)
            return received;

        length -= received;
        buffer += received;
    }

    return 0;
}

typedef struct my_string *(*handler)(struct my_list *, char **, int *);

int main()
{
    handler handlers[6] = {list_all_handler, add_handler, get_handler, remove_handler, count_handler};
    struct my_list main_list = list_create();

    int clients[65536];
    int client_count = 0;

    int server = socket(AF_INET, SOCK_STREAM, 0);
    int reuse = 1;
    setsockopt(server, SOL_SOCKET, SO_REUSEADDR, &reuse, sizeof(int));
    struct sockaddr_in server_addr;
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    server_addr.sin_port = htons(PORT);
    if (bind(server, (struct sockaddr *)&server_addr, sizeof(server_addr)))
    {
        puts("bind failed");
        return 1;
    }
    listen(server, 5);

    struct sockaddr_in client;
    socklen_t socklen = sizeof(client);
    struct pollfd ufd_srv;
    ufd_srv.fd = server;
    ufd_srv.events = POLLIN;
    while (1)
    {
        int srv_poll = poll(&ufd_srv, 1, 20);
        if (srv_poll)
            clients[client_count++] = accept(server, (struct sockaddr *)&client, &socklen);

        struct pollfd ufd_cl;
        ufd_cl.events = POLLIN;
        for (int i = 0; i < client_count; i++)
        {
            ufd_cl.fd = clients[i];
            int cl_poll = poll(&ufd_cl, 1, 20);
            if (!cl_poll)
                continue;

            int conn = clients[i];
            char inp[2];
            if (recvall(conn, inp, 2) < 0)
            {
                close(conn);
                continue;
            }

            int command = inp[0];
            int argc = inp[1];
            int recv_successful = 1;
            char **argv = (char **)malloc(sizeof(char *) * argc);
            for (int i = 0; i < argc; i++)
            {
                int arg_len;
                if (recvall(conn, (char *)&arg_len, 4) < 0)
                {
                    argc = i - 1;
                    recv_successful = 0;
                    break;
                }
                arg_len = ntohl(arg_len);
                argv[i] = (char *)malloc(sizeof(char) * (arg_len + 1));
                if (recvall(conn, argv[i], arg_len) < 0)
                {
                    argc = i;
                    recv_successful = 0;
                    break;
                }
                argv[i][arg_len] = '\0';
            }

            if (recv_successful)
            {
                int resc;
                struct my_string *res = handlers[command](&main_list, argv, &resc);

                printf("command: %d\n", command);
                printf("args: ");
                for (int i = 0; i < argc; i++)
                {
                    printf("%s, ", argv[i]);
                }
                printf("res: ");
                for (int i = 0; i < resc; i++)
                {
                    printf("%s, ", res[i].s);
                }
                puts("");

                int send_successful = 1;
                if (sendall(conn, (char *)"\0", 1) < 0)
                    send_successful = 0;
                if (send_successful && sendall(conn, (char *)&resc, 1) < 0)
                    send_successful = 0;
                if (send_successful)
                {
                    for (int i = 0; i < resc; i++)
                    {
                        int arg_len = htonl(res[i].c);
                        if (sendall(conn, (char *)&arg_len, 4) < 0)
                            break;
                        if (sendall(conn, res[i].s, res[i].c) < 0)
                            break;
                    }
                }

                for (int i = 0; i < resc; i++)
                    free(res[i].s);
                free(res);
            }

            for (int i = 0; i < argc; i++)
                free(argv[i]);
            free(argv);
        }
    }
}
