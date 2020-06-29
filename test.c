/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   test.c                                             :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: ajeannot <ajeannot@student.42.fr>          +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2020/03/09 11:28:51 by ajeannot          #+#    #+#             */
/*   Updated: 2020/03/09 11:37:09 by ajeannot         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include <stdio.h>

int main(int argc, char **argv)
{
    int count;

    count = 1;
    if (argc < 2)
        printf("Less than 2 args\n");
    else
        while (count < argc)
        {
            printf("Argument %d = %s\n", count, argv[count]);
            count++;
        }
    return (0);
}
