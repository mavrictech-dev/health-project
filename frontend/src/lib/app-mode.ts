/** Build-time choice. Live is the default, including the Docker frontend. */
export const isMockMode = process.env.NEXT_PUBLIC_APP_MODE === 'mock';
