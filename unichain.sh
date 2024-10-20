#!/bin/bash

GREEN='\033[0;32m'
RESET='\033[0m'

display_logo() {
    logo="
    \033[32m
 __     __  _______   __    __  __    __  _______  
|  \   |  \|       \ |  \  |  \|  \  |  \|       \ 
| $$   | $$| $$$$$$$\| $$  | $$| $$  | $$| $$$$$$$\
| $$   | $$| $$  | $$| $$__| $$| $$  | $$| $$__/ $$
 \$$\ /  $$| $$  | $$| $$    $$| $$  | $$| $$    $$
  \$$\  $$ | $$  | $$| $$$$$$$$| $$  | $$| $$$$$$$\
   \$$ $$  | $$__/ $$| $$  | $$| $$__/ $$| $$__/ $$
    \$$$   | $$    $$| $$  | $$ \$$    $$| $$    $$
     \$     \$$$$$$$  \$$   \$$  \$$$$$$  \$$$$$$$   
    \033[0m
    Підпишись на наш канал VDHUB, щоб бути в курсі найактуальніших новин про ноди! Приєднуйся за посиланням: [https://t.me/vdhub_crypto]
    "
    echo -e "$logo"
}

show_menu() {
    clear
    display_logo
    echo -e "${GREEN}Ласкаво просимо до інтерфейсу керування вузлом Uniswap.${RESET}"
    echo -e "${GREEN}Будь ласка, виберіть опцію:${RESET}"
    echo
    echo -e "${GREEN}1.${RESET} Встановити вузол"
    echo -e "${GREEN}2.${RESET} Перезапустити вузол"
    echo -e "${GREEN}3.${RESET} Перевірити вузол"
    echo -e "${GREEN}4.${RESET} Переглянути логи операційного вузла"
    echo -e "${GREEN}5.${RESET} Переглянути логи клієнта виконання"
    echo -e "${GREEN}6.${RESET} Вимкнути вузол"
    echo -e "${GREEN}0.${RESET} Вихід"
    echo
    echo -e "${GREEN}Введіть ваш вибір [0-6]: ${RESET}"
    read -p " " choice
}

install_node() {
    cd
    if docker ps -a --format '{{.Names}}' | grep -q "^unichain-node-execution-client-1$"; then
        echo -e "${GREEN}1. Вузол вже встановлений.${RESET}"
    else
        echo -e "${GREEN}1. Встановлення вузла...${RESET}"
        sudo apt update && sudo apt upgrade -y
        sudo apt install docker.io -y
        sudo systemctl start docker
        sudo systemctl enable docker

        sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose

        git clone https://github.com/Uniswap/unichain-node
        cd unichain-node || { echo -e "${GREEN}Не вдалося увійти до директорії unichain-node.${RESET}"; return; }

        if [[ -f .env.sepolia ]]; then
            sed -i 's|^OP_NODE_L1_ETH_RPC=.*$|OP_NODE_L1_ETH_RPC=https://ethereum-sepolia-rpc.publicnode.com|' .env.sepolia
            sed -i 's|^OP_NODE_L1_BEACON=.*$|OP_NODE_L1_BEACON=https://ethereum-sepolia-beacon-api.publicnode.com|' .env.sepolia
        else
            echo -e "${GREEN}.env.sepolia файл не знайдено!${RESET}"
            return
        fi

        sudo docker-compose up -d

        echo -e "${GREEN}1. Вузол успішно встановлений.${RESET}"
    fi
    echo
    read -p "Натисніть Enter, щоб повернутися до головного меню..."
}

restart_node() {
    echo -е "${GREEN}2. Перезапуск вузла...${RESET}"
    HOMEDIR="$HOME"
    sudo docker-compose -f "${HOMEDIR}/unichain-node/docker-compose.yml" down
    sudo docker-compose -f "${HOMEDIR}/unichain-node/docker-compose.yml" up -d
    echo -e "${GREEN}2. Вузол перезапущений.${RESET}"
    echo
    read -p "Натисніть Enter, щоб повернутися до головного меню..."
}

check_node() {
    echo -e "${GREEN}3. Перевірка статусу вузла...${RESET}"
    response=$(curl -s -d '{"id":1,"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",false]}' \
      -H "Content-Type: application/json" http://localhost:8545)
    echo -e "${GREEN}Відповідь: ${RESET}$response"
    echo
    read -p "Натисніть Enter, щоб повернутися до головного меню..."
}

check_logs_op_node() {
    echo -e "${GREEN}4. Отримання логів для unichain-node-op-node-1...${RESET}"
    sudo docker logs unichain-node-op-node-1
    echo
    read -p "Натисніть Enter, щоб повернутися до головного меню..."
}

check_logs_execution_client() {
    echo -e "${GREEN}5. Отримання логів для unichain-node-execution-client-1...${RESET}"
    sudo docker logs unichain-node-execution-client-1
    echo
    read -p "Натисніть Enter, щоб повернутися в головне меню...."
}

disable_node() {
    echo -e "${GREEN}6. Відключення вузла....${RESET}"
    HOMEDIR="$HOME"
    sudo docker-compose -f "${HOMEDIR}/unichain-node/docker-compose.yml" down
    echo -e "${GREEN}6. Вузол відключено.${RESET}"
    echo
    read -p "Натисніть Enter, щоб повернутися в головне меню...."
}

while true; do
    show_menu
    case $choice in
        1)
            install_node
            ;;
        2)
            restart_node
            ;;
        3)
            check_node
            ;;
        4)
            check_logs_op_node
            ;;
        5)
            check_logs_execution_client
            ;;
        6)
            disable_node
            ;;
        0)
            echo -e "${GREEN}Вихід...${RESET}"
            exit 0
            ;;
        *)
            echo -e "${GREEN}Невірний вибір. Спробуйте ще раз.${RESET}"
            echo
            read -p "Натисніть Enter, щоб продовжити..."
            ;;
    esac
done
