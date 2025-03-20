import { DateTime } from 'luxon';  // Importer Luxon pour la gestion du fuseau horaire

export const handler = async (event, context) => {

    // Récupérer l'heure actuelle à Paris et la formater
    const parisTime = DateTime.now().setZone('Europe/Paris');
    const timeString = parisTime.toFormat('HH:mm');

    // Construire le message avec l'heure à Paris
    const message = `Hello World ! Ici Antoine PROVAIN & Hugo CHAPERON, à ${timeString}`;

    console.log(response);
    return {
        message,
        response
    };
};
