import { DateTime } from 'luxon';

export const handler = async () => {
    // Récupérer l'heure actuelle à Paris et la formater
    const parisTime = DateTime.now().setZone('Europe/Paris');
    const timeString = parisTime.toFormat('HH:mm');

    // Construire le message avec l'heure à Paris
    const message = `Hello World ! Ici Antoine PROVAIN & Hugo CHAPERON, à ${timeString}`;

    // Log pour débogage
    console.log("Message:", message);

    // Retourner un objet JSON avec un statusCode et body
    return {
        statusCode: 200,  // Statut HTTP OK
        body: JSON.stringify({ message }),  // Message JSON
    };
};
